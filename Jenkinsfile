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
                        string(credentialsId: 'ansible-vault-password', variable: 'VAULT_PASSWORD')
                    ]) {
                        sh '''
                            set -eu
                            set +x

                            VAULT_FILE=$(mktemp)
                            trap 'rm -f "$VAULT_FILE"' EXIT

                            printf '%s' "$VAULT_PASSWORD" > "$VAULT_FILE"
                            chmod 600 "$VAULT_FILE"
                            export ANS