import copy
import json
import yaml

with open("inventory.yml", encoding="utf-8") as f:
    inventory = yaml.safe_load(f)

with open("ansible_inventory.json", encoding="utf-8") as f:
    ips = json.load(f)

generated = copy.deepcopy(inventory)
children = generated["all"]["children"]

for group, target in [
    ("masters", "k8s_masters"),
    ("workers", "k8s_workers"),
    ("minio", "minio"),
]:
    # Vérifie si le groupe existe bien dans le JSON pour éviter les erreurs KeyError
    if group in ips and target in children:
        for hostname, ip in ips[group].items():
            # Initialise le dictionnaire "hosts" s'il n'existe pas encore
            if "hosts" not in children[target]:
                children[target]["hosts"] = {}
            
            # Initialise l'hôte s'il n'existe pas
            if hostname not in children[target]["hosts"]:
                children[target]["hosts"][hostname] = {}
                
            children[target]["hosts"][hostname]["ansible_host"] = ip

with open("inventory.generated.yaml", "w", encoding="utf-8") as f:
    yaml.safe_dump(generated, f, sort_keys=False, allow_unicode=True)