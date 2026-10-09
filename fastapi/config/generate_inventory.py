import copy
import json
import yaml

with open("inventory.yaml", encoding="utf-8") as f:
    inventory = yaml.safe_load(f)

with open("ansible_inventory.json", encoding="utf-8") as f:
    ips = json.load(f)

generated = copy.deepcopy(inventory)
children = generated["all"]["children"]

# Supprime le groupe Proxmox s'il existe
children.pop("proxmox", None)

for group, target in [
    ("masters", "k8s_masters"),
    ("workers", "k8s_workers"),
    ("minio", "minio"),
]:
    if group in ips and target in children:
        if "hosts" not in children[target]:
            children[target]["hosts"] = {}

        for hostname, ip in ips[group].items():
            if hostname not in children[target]["hosts"]:
                children[target]["hosts"][hostname] = {}

            children[target]["hosts"][hostname]["ansible_host"] = ip

with open("inventory.generated.yaml", "w", encoding="utf-8") as f:
    yaml.safe_dump(generated, f, sort_keys=False, allow_unicode=True)