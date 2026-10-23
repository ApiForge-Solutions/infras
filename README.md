infras — Infrastructure ApiForge Solutions

Provisionnement et configuration automatisés d'une plateforme Kubernetes haute disponibilité sur un hyperviseur Proxmox, centrée sur Traefik, qui héberge une application FastAPI (backend, frontend, PostgreSQL).

Chaîne complète : Terraform (VM) → Ansible (cluster et services) → Helm (application), le tout orchestré par Jenkins.

Architecture
Internet ──► Proxmox (DNAT 80/443) ──► 10.10.10.200 (MetalLB) ──► Traefik ──► frontend / backend ──► PostgreSQL
                                         API Kubernetes : VIP kube-vip 10.10.10.99
Composant	Rôle	Outil
3 masters + 2 workers	Cluster Kubernetes HA (etcd empilé)	kubeadm, containerd, Calico
VIP de l'API	Point d'entrée unique du control plane	kube-vip (ARP)
IP de service	Adresse du load balancer	MetalLB (L2, 10.10.10.200-210)
Entrée HTTP(S)	Routage, dashboard, services externes	Traefik (Helm)
Certificats	Let's Encrypt (HTTP-01)	cert-manager
Sauvegardes	Backups Kubernetes vers S3	Velero + MinIO (VM dédiée)
Supervision	Métriques, tableaux de bord, alertes e-mail	Prometheus, Grafana, Alertmanager, node_exporter (VM dédiée)
CI/CD	Pipeline complet	Jenkins (VM dédiée)
GitOps en place	ArgoCD
Organisation du dépôt
Jenkinsfile                  Pipeline : build, Terraform, Ansible, déploiement Helm
fastapi/
  infra/                     Terraform : modules network, vm_kubernetes, vm_admin
  config/                    Ansible : playbook.yaml, inventory.yaml, group_vars/, roles/
  app/                       Chart Helm de l'application
outils_admin/
  terraform_jenkins/         VM Jenkins (Terraform)
  ansible_jenkins/           Installation de Jenkins (Ansible)

Rôles Ansible : k8s, k8s-master, k8s-worker, helm, metallb, cert-manager, traefik, velero, minio, monitoring, node-exporter, argocd, proxmox-traffic.

Prérequis
Un nœud Proxmox avec un accès API (jeton) et un modèle de VM Ubuntu.
Une machine de contrôle avec Terraform, Python 3, Ansible (voir fastapi/config/install_ansible.sh), kubectl et helm.
Un nom de domaine dont les enregistrements A pointent vers l'IP publique de Proxmox, avec une redirection des ports 80 et 443 vers 10.10.10.200 (nécessaire pour Let's Encrypt HTTP-01).
Une paire de clés SSH.
Secrets

Aucun secret ne doit être commité en clair.

Secret	Où
Mots de passe Dashboard Traefik, Grafana, MinIO, Velero, SMTP	fastapi/config/group_vars/all/vault.yml (Ansible Vault)
Mot de passe du vault	Credential Jenkins ansible-vault-password (jamais dans le dépôt)
Accès Proxmox	Credentials Jenkins proxmox-endpoint, proxmox-token
Clés SSH	Credentials Jenkins ssh-public-key, ssh-private-key
Secrets applicatifs	Credentials Jenkins postgres-user, postgres-password, first-superuser-password, fastapi-secret-key

Éditer le vault : ansible-vault edit fastapi/config/group_vars/all/vault.yml

Installation
Option A — via Jenkins (recommandé)
Installer Jenkins : voir outils_admin/ (Terraform puis Ansible).
Créer les credentials listés ci-dessus.
Créer un job Pipeline from SCM pointant sur ce dépôt (branche dev).
Lancer le build. Étapes : build et push des images → terraform apply → génération de l'inventaire → ansible-playbook → helm upgrade --install.
Option B — à la main
bash
# 1. VM
cd fastapi/infra
export PROXMOX_VE_ENDPOINT=...  PROXMOX_VE_API_TOKEN=...  TF_VAR_ssh_public_key="$(cat ~/.ssh/id_ed25519.pub)"
terraform init && terraform apply -var-file=terraform.tfvars
terraform output -json ansible_inventory > ../config/ansible_inventory.json

# 2. Inventaire puis cluster
cd ../config
python3 generate_inventory.py
ansible-playbook -i inventory.generated.yaml playbook.yaml --ask-vault-pass

# 3. Application
cd ../app
helm upgrade --install fastapi . --namespace default \
  --set-string secrets.postgresUser=... --set-string secrets.postgresPassword=... \
  --set-string secrets.postgresDb=fastapi --set-string secrets.secretKey=... \
  --set-string secrets.firstSuperuserPassword=...
Variables principales (fastapi/config/group_vars/all/main.yml)
Variable	Rôle
KUBERNETES_VERSION	Version de Kubernetes (ex. v1.29)
K8S_API_VIP / K8S_API_ENDPOINT	VIP et nom de l'API (kube-vip)
METALLB_IP_RANGE / TRAEFIK_LB_IP	Plage MetalLB et IP de Traefik
TERRAFORM_APP_DOMAIN	Domaine public
LETSENCRYPT_ISSUER	letsencrypt-staging pour tester, letsencrypt-prod en production
ALLOWED_SOURCE_RANGES	IP autorisées pour dashboard et outils d'administration (jamais 0.0.0.0/0)
MINIO_S3_URL / BUCKET_NAME	Cible des sauvegardes Velero
Vérifier l'installation
bash
kubectl get nodes                        # 5 nœuds Ready
kubectl -n traefik get svc               # EXTERNAL-IP = 10.10.10.200
kubectl get certificate -A               # READY = True
velero backup get                        # sauvegardes nocturnes

Interfaces : application, traefik.<domaine>, Grafana, Prometheus.

Sauvegarde et restauration

Velero sauvegarde chaque nuit vers MinIO.

Limites connues
Un seul nœud Proxmox : la haute disponibilité protège des pannes de VM, pas de l'hôte.
PostgreSQL en instance unique avec volume hostPath (liée à un nœud).
Vérification des clés SSH désactivée pendant la récupération du kubeconfig par Jenkins (lab).
Le DNAT sur Proxmox est partagé avec d'autres locataires : ne jamais vider les règles iptables.
Auteurs et licence

Équipe ApiForge Solutions, projet DataScientest — Ingénieur DevOps. Licence : voir LICENSE.
