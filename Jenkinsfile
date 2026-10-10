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
                        string(credentialsId: 'fastapi-secret-key', variable: 'SECRET_KEY')
                    ]) {
                        sh '''
                            set -eu
                            set +x

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

                            kubectl create secret generic db-secret \
                                --from-literal=POSTGRES_USER="$POSTGRES_USER" \
                                --from-literal=POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
                                --from-literal=POSTGRES_DB=fastapi \
                                --dry-run=client -o yaml | kubectl apply -f -

                            kubectl create secret generic fastapi-secret \
                                --from-literal=POSTGRES_USER="$POSTGRES_USER" \
                                --from-literal=POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
                                --from-literal=FIRST_SUPERUSER_PASSWORD="$FIRST_SUPERUSER_PASSWORD" \
                                --from-literal=SECRET_KEY="$SECRET_KEY" \
                                --dry-run=client -o yaml | kubectl apply -f -

                            helm lint .
                            helm upgrade --install fastapi .

                            kubectl rollout restart statefulset/db
                            kubectl rollout status statefulset/db --timeout=180s

                            kubectl get pods
                        '''
                    }
                }
            }
        }
    }
}