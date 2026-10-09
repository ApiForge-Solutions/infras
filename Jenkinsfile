pipeline {
agent any

environment {
    TF_IN_AUTOMATION = 'true'
}

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
                        variable: 'TF_VAR_ssh_public_key'
                    )
                ]) {
                    sh 'terraform init'
                    sh 'terraform validate'
                    sh 'terraform apply -auto-approve -var-file="terraform.tfvars"'
                    sh 'terraform output -json ansible_inventory > ../config/ansible_inventory.json'
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
                        set +x
                        VAULT_FILE=$(mktemp)
                        trap 'rm -f "$VAULT_FILE"' EXIT

                        printf '%s' "$VAULT_PASSWORD" > "$VAULT_FILE"
                        export ANSIBLE_VAULT_PASSWORD_FILE="$VAULT_FILE"

                        python3 generate_inventory.py
                        ansible-inventory -i inventory.generated.yml --graph
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
                    )
                ]) {
                    sh '''
                        set +x
                        VAULT_FILE=$(mktemp)
                        trap 'rm -f "$VAULT_FILE"' EXIT

                        printf '%s' "$VAULT_PASSWORD" > "$VAULT_FILE"
                        export ANSIBLE_VAULT_PASSWORD_FILE="$VAULT_FILE"

                        ansible-playbook -i inventory.generated.yml playbook.yaml
                    '''
                }
            }
        }
    }
}


}
