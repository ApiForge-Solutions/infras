import copy
import json

import yaml

with open("inventory.yml", "r", encoding="utf-8") as file:
inventory = yaml.safe_load(file)

with open("ansible_inventory.json", "r", encoding="utf-8") as file:
ips = json.load(file)

generated = copy.deepcopy(inventory)
children = generated["all"]["children"]

# Mise à jour des machines Kubernetes

for group_name in ("masters", "workers"):
inventory_group = {
"masters": "k8s_masters",
"workers": "k8s_workers",
}[group_name]


hosts = children[inventory_group]["hosts"]

for hostname, ip in ips[group_name].items():
    if hostname not in hosts:
        raise ValueError(
            f"Machine inconnue dans l'inventaire : {hostname}"
        )

    hosts[hostname]["ansible_host"] = ip


# Mise à jour du serveur MinIO

minio_hosts = children["minio"]["hosts"]

for hostname, ip in ips["minio"].items():
if hostname not in minio_hosts:
raise ValueError(
f"Machine inconnue dans l'inventaire : {hostname}"
)


minio_hosts[hostname]["ansible_host"] = ip

# Génération de l'inventaire final

with open("inventory.generated.yml", "w", encoding="utf-8") as file:
yaml.safe_dump(
generated,
file,
sort_keys=False,
allow_unicode=True
)

print("Inventaire Ansible généré avec succès.")
