pipeline {
    agent any

    stages {
        stage('Récupération du dépôt infrastructure') {
    steps {
        dir('infras') {
            git branch: 'dev',
                url: 'https://github.com/ApiForge-Solutions/infras.git'
        }
    }
}
        stage('récupération du code de base') {
    steps {
        git branch: 'main',
            url: 'https://github.com/DataScientest/fastapi-traefik-datascientest-project.git'
    }
}
stage('Connexion Docker') {
            environment {
                DOCKER_HUB_PASS = credentials('DOCKER_HUB_PASS')
            }

            steps {
                sh '''
                echo $DOCKER_HUB_PASS | docker login \
                -u apiforgesolutions \
                --password-stdin
                '''
            }
        }
         stage('Build Docker') {
            steps {
                sh '''
                export DOCKER_BUILDKIT=1
                docker build -t apiforgesolutions/api_traefik:backend ./backend
                docker build -t apiforgesolutions/api_traefik:frontend ./frontend
                '''
            }
        }

        stage('Push Docker') {
            steps {
                sh '''
                docker push apiforgesolutions/api_traefik:backend
                docker push apiforgesolutions/api_traefik:frontend
                '''
            }
        }

    

        stage('Install infra terraform ') {
            steps {
                dir('infras/fastapi/infra') {
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

        stage(' création inventaire pour Ansible') {
            steps {
                dir('infras/fastapi/config') {
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

        stage('Install cluster Ansible') {
            steps {
                dir('infras/fastapi/config') {
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


        stage('Kubeconfig pour le pipeline applicatif') {
            steps {
                dir('infras/fastapi/config') {
                    withCredentials([sshUserPrivateKey(credentialsId: 'ssh-private-key', keyFileVariable: 'SSH_KEY')]) {
                        sh '''
                            set -eu
                            set +x
                            umask 077

                            MASTER_IP=$(python3 -c 'import json; print(json.load(open("ansible_inventory.json"))["masters"]["master_01"])')
                            API_SERVER="https://10.10.10.99:6443"
                            DEST="$JENKINS_HOME/.kube/fastapi-config"
                            mkdir -p "$(dirname "$DEST")"
                            TMP=$(mktemp)
                            trap 'rm -f "$TMP"' EXIT

                            ssh -i "$SSH_KEY" -o BatchMode=yes -o ConnectTimeout=10 \
                                -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                                -o LogLevel=ERROR "ubuntu@$MASTER_IP" \
                                'sudo cat /etc/kubernetes/admin.conf' > "$TMP"
                            test -s "$TMP"

                            CLUSTER=$(kubectl --kubeconfig="$TMP" config view --minify \
                                -o jsonpath='{.clusters[0].name}')
                            kubectl --kubeconfig="$TMP" config set-cluster "$CLUSTER" \
                                --server="$API_SERVER" >/dev/null

                            # Le fichier n'est écrasé que si le cluster répond
                            kubectl --kubeconfig="$TMP" get nodes
                            mv "$TMP" "$DEST"
                            chmod 600 "$DEST"
                        '''
                    }
                }
            }
        }

        stage('Déploiement applicatif (pipeline GitOps)') {
            steps {
                build job: 'fastapi-ci-cd',
                        parameters: [string(name: 'ACTION', value: 'pipeline')],
                        wait: true,
                        propagate: true
            }
        }
    }
}