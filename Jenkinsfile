pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init and Apply') {
            steps {
                dir('fastapi/infra') {
                    withCredentials([
                        string(credentialsId: 'proxmox-endpoint', variable: 'PROXMOX_VE_ENDPOINT'),
                        string(credentialsId: 'proxmox-token', variable: 'PROXMOX_VE_API_TOKEN'),
                        string(credentialsId: 'ssh-public-key', variable: 'SSH_PUBLIC_KEY')
                    ]) {
                        sh '''
                            set -eu
                            set +x

                            export TF_VAR_ssh_public_key="$SSH_PUBLIC_KEY"

                            terraform init
                            terraform validate
                            terraform apply -auto-approve -var-file=terraform.tfvars

                            terraform output -json ansible_inventory > ../config/ansible_inventory.json
                        '''
                    }
                }
            }
        }

        stage('Generate Ansible Inventory') {
            steps {
                dir('fastapi/config') {
                    withCredentials([
                        string(credentialsId: 'ansible-vault-password', variable: 'VAULT_PASSWORD')
                    ]) {
                        sh '''
                            set -eu
                            set +x

                            VAULT_FILE=$(mktemp)
                            trap 'rm -f "$VAULT_FILE"' EXIT

                            printf '%s' "$VAULT_PASSWORD" > "$VAULT_FILE"
                            chmod 600 "$VAULT_FILE"

                            export ANSIBLE_VAULT_PASSWORD_FILE="$VAULT_FILE"

                            python3 generate_inventory.py
                            ansible-inventory -i inventory.generated.yaml --graph
                        '''
                    }
                }
            }
        }

        stage('Run Ansible') {
            steps {
                dir('fastapi/config') {
                    withCredentials([
                        string(credentialsId: 'ansible-vault-password', variable: 'VAULT_PASSWORD'),
                        sshUserPrivateKey(credentialsId: 'ssh-private-key', keyFileVariable: 'SSH_KEY')
                    ]) {
                        sh '''
                            set -eu
                            set +x

                            VAULT_FILE=$(mktemp)
                            trap 'rm -f "$VAULT_FILE"' EXIT

                            printf '%s' "$VAULT_PASSWORD" > "$VAULT_FILE"
                            chmod 600 "$VAULT_FILE"

                            export ANSIBLE_VAULT_PASSWORD_FILE="$VAULT_FILE"
                            export ANSIBLE_PRIVATE_KEY_FILE="$SSH_KEY"

                            ansible-playbook -i inventory.generated.yaml playbook.yaml
                        '''
                    }
                }
            }
        }

        stage('Deploy on Kubernetes') {
            steps {
                dir('fastapi/app') {
                    withCredentials([
                        string(credentialsId: 'postgres-user', variable: 'POSTGRES_USER'),
                        string(credentialsId: 'postgres-password', variable: 'POSTGRES_PASSWORD'),
                        string(credentialsId: 'first-superuser-password', variable: 'FIRST_SUPERUSER_PASSWORD'),
                        string(credentialsId: 'fastapi-secret-key', variable: 'SECRET_KEY'),
                        sshUserPrivateKey(credentialsId: 'ssh-private-key', keyFileVariable: 'SSH_KEY')
                    ]) {
                        sh '''
                            set -eu
                            set +x

                            echo "=== 1. Vérification des credentials ==="

                            test -n "$POSTGRES_USER" || {
                                echo "ERREUR : postgres-user est vide."
                                exit 1
                            }

                            test -n "$POSTGRES_PASSWORD" || {
                                echo "ERREUR : postgres-password est vide."
                                exit 1
                            }

                            test -n "$FIRST_SUPERUSER_PASSWORD" || {
                                echo "ERREUR : first-superuser-password est vide."
                                exit 1
                            }

                            test -n "$SECRET_KEY" || {
                                echo "ERREUR : fastapi-secret-key est vide."
                                exit 1
                            }

                            echo "Credentials présents : OK"

                            echo "=== 2. Récupération du kubeconfig actuel ==="

                            test -s ../config/ansible_inventory.json || {
                                echo "ERREUR : ansible_inventory.json est absent."
                                exit 1
                            }

                            MASTER_IP=$(python3 -c '
import json
with open("../config/ansible_inventory.json", encoding="utf-8") as f:
    print(json.load(f)["masters"]["master_01"])
')

                            test -n "$MASTER_IP" || {
                                echo "ERREUR : IP du master introuvable."
                                exit 1
                            }

                            # Lire l'adresse API déjà utilisée par Jenkins.
                            # Cette lecture locale ne contacte pas le cluster.
                            CURRENT_API_SERVER=$(kubectl config view --minify \
                                -o jsonpath='{.clusters[0].cluster.server}' 2>/dev/null || true)

                            umask 077
                            KUBECONFIG_FILE=$(mktemp)
                            trap 'rm -f "$KUBECONFIG_FILE"' EXIT

                            # Le cluster ayant été recréé, la clé SSH de la VM
                            # peut avoir changé. La vérification SSH est ignorée
                            # uniquement pour cette récupération dans ce lab.
                            ssh -i "$SSH_KEY" \
                                -o BatchMode=yes \
                                -o ConnectTimeout=10 \
                                -o StrictHostKeyChecking=no \
                                -o UserKnownHostsFile=/dev/null \
                                -o LogLevel=ERROR \
                                "ubuntu@$MASTER_IP" \
                                'sudo cat /etc/kubernetes/admin.conf' \
                                > "$KUBECONFIG_FILE"

                            test -s "$KUBECONFIG_FILE" || {
                                echo "ERREUR : le kubeconfig récupéré est vide."
                                exit 1
                            }

                            chmod 600 "$KUBECONFIG_FILE"

                            # Conserver l'endpoint joignable depuis Jenkins,
                            # mais utiliser l'autorité de certification actuelle.
                            if [ -n "$CURRENT_API_SERVER" ]; then
                                NEW_CLUSTER=$(kubectl --kubeconfig="$KUBECONFIG_FILE" \
                                    config view --minify \
                                    -o jsonpath='{.clusters[0].name}')

                                kubectl --kubeconfig="$KUBECONFIG_FILE" \
                                    config set-cluster "$NEW_CLUSTER" \
                                    --server="$CURRENT_API_SERVER" >/dev/null
                            fi

                            export KUBECONFIG="$KUBECONFIG_FILE"

                            echo "=== 3. Test de connexion Kubernetes ==="

                            # En cas d'erreur, arrêter AVANT toute modification.
                            kubectl get nodes

                            echo "=== 4. Validation du chart Helm ==="

                            helm lint .

                            echo "=== 5. Mise à jour du Secret applicatif ==="

                            kubectl create secret generic fastapi-secret \
                                --from-literal=POSTGRES_USER="$POSTGRES_USER" \
                                --from-literal=POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
                                --from-literal=FIRST_SUPERUSER_PASSWORD="$FIRST_SUPERUSER_PASSWORD" \
                                --from-literal=SECRET_KEY="$SECRET_KEY" \
                                --dry-run=client -o yaml | kubectl apply -f -

                            echo "=== 6. Mise à jour de l'application avec Helm ==="

                            helm upgrade --install fastapi . \
                                --namespace default \
                                --set-string secrets.postgresUser="$POSTGRES_USER" \
                                --set-string secrets.postgresPassword="$POSTGRES_PASSWORD" \
                                --set-string secrets.postgresDb=fastapi \
                                --set-string secrets.secretKey="$SECRET_KEY" \
                                --set-string secrets.firstSuperuserPassword="$FIRST_SUPERUSER_PASSWORD" \
                                --wait \
                                --timeout 5m

                            echo "=== 7. Vérification finale ==="

                            kubectl rollout status statefulset/db \
                                -n default --timeout=180s

                            kubectl get pods -n default
                            kubectl get pvc -n default
                            kubectl get pv

                            echo "=== Déploiement terminé ==="
                        '''
                    }
                }
            }
        }
    }
}