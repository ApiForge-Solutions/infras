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
                        )
                    ]) {
                        sh 'terraform init'
                        sh 'terraform validate'
                        sh 'terraform apply -auto-approve'
                        sh 'terraform output -json ansible_inventory > ../config/ansible_inventory.json'
                    }
                }
            }
        }

        stage('Generate Ansible Inventory') {
            steps {
                dir('fastapi/config') {
                    sh 'python3 generate_inventory.py'
                    sh 'ansible-inventory -i inventory.generated.yml --graph'
                }
            }
        }

        stage('Run Ansible') {
            steps {
                dir('fastapi/config') {
                    sh 'ansible-playbook -i inventory.generated.yml playbook.yml'
                }
            }
        }
    }
}