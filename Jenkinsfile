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
                        string(
                            credentialsId: 'proxmox-endpoint',
                            variable: 'PROXMOX_VE_ENDPOINT'
                        ),
                        string(
                            credentialsId: 'proxmox-token',
                            variable: 'PROXMOX_VE_API_TOKEN'
                        ),
                        string(
                            credentialsId: 'ssh-public-key',
                            variable: 'SSH_PUBLIC_KEY'
                        )
                    ]) {
                        sh '''
                            set -e
                            set +x

                            export TF_VAR_ssh_public_key="$SSH_PUBLIC_KEY"

                            terraform init
                            terraform validate
                            terraform apply -auto-approve -var-file="terraform.tfvars"

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
                        string(
                            credentialsId: 'ansible-vault-password',
                            variable: 'VAULT_PASSWORD'
                        )
                    ]) {
                        sh '''
                            set -e
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
                        string(
                            credentialsId: 'ansible-vault-password',
                            variable: 'VAULT_PASSWORD'
                        ),
                        sshUserPrivateKey(
                            credentialsId: 'ssh-private-key',
                            keyFileVariable: 'SSH_KEY'
                        )
                    ]) {
                        sh '''
                            set -e
                            set +x

                            VAULT_FILE=$(mktemp)
                            trap 'rm -f "$VAULT_FILE"' EXIT

                            printf '%s' "$VAULT_PASSWORD" > "$VAULT_FILE"
                            chmod 600 "$VAULT_FILE"
                            export ANSIBLE_VAULT_PASSWORD_FILE="$VAULT_FILE"
                            export ANSIBLE_PRIVATE_KEY_FILE="$SSH_KEY"

                            ansible-playbook \
                                -i inventory.generated.yaml \
                                playbook.yaml
                        '''
                    }
                }
            }
        }

        stage('Deploy on Kubernetes') {
            steps {
                dir('fastapi/app') {
                    withCredentials([
                        string(
                            credentialsId: 'postgres-user',
                            variable: 'POSTGRES_USER'
                        ),
                        string(
                            credentialsId: 'postgres-password',
                            variable: 'POSTGRES_PASSWORD'
                        ),
                        string(
                            credentialsId: 'first-superuser-password',
                            variable: 'FIRST_SUPERUSER_PASSWORD'
                        ),
                        string(
                            credentialsId: 'fastapi-secret-key',
                            variable: 'SECRET_KEY'
                        )
                    ]) {
                        sh '''
                            set -e
                            set +x

                            # Vérifier que les credentials Jenkins sont renseignés
                            if [ -z "$POSTGRES_USER" ]; then
                                echo "ERREUR : le credential postgres-user est vide."
                                exit 1
                            fi

                            if [ -z "$POSTGRES_PASSWORD" ]; then
                                echo "ERREUR : le credential postgres-password est vide."
                                exit 1
                            fi

                            if [ -z "$FIRST_SUPERUSER_PASSWORD" ]; then
                                echo "ERREUR : le credential first-superuser-password est vide."
                                exit 1
                            fi

                            if [ -z "$SECRET_KEY" ]; then
                                echo "ERREUR : le credential fastapi-secret-key est vide."
                                exit 1
                            fi

                            echo "Vérification des credentials : OK"

                            # Secret utilisé par PostgreSQL
                            kubectl create secret generic db-secret \
                                --from-literal=POSTGRES_USER="$POSTGRES_USER" \
                                --from-literal=POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
                                --from-literal=POSTGRES_DB="fastapi" \
                                --dry-run=client -o yaml | kubectl apply -f -

                            # Secret utilisé par FastAPI
                            kubectl create secret generic fastapi-secret \
                                --from-literal=POSTGRES_USER="$POSTGRES_USER" \
                                --from-literal=POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
                                --from-literal=FIRST_SUPERUSER_PASSWORD="$FIRST_SUPERUSER_PASSWORD" \
                                --from-literal=SECRET_KEY="$SECRET_KEY" \
                                --dry-run=client -o yaml | kubectl apply -f -

                            # Vérifier le chart Helm
                            helm lint .

                            # Déployer ou mettre à jour l'application
                            helm upgrade --install fastapi .
                        '''
                    }
                }
            }
        }
    }
}