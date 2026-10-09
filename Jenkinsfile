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
            dir('infra/fastapi/infra') {
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
            dir('infra/fastapi/config') {
                sh 'python3 generate_inventory.py'
                sh 'ansible-inventory -i inventory.generated.yml --graph'
            }
        }
    }

    stage('Run Ansible') {
        steps {
            dir('infra/fastapi/config') {
                sh 'ansible-playbook -i inventory.generated.yml playbook.yml'
            }
        }
    }
}
}
