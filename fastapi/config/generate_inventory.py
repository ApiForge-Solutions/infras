
import copy
import json
import yaml

with open("inventory.yml") as f:
    inventory = yaml.safe_load(f)

with open("ansible_inventory.json") as f:
    ips = json.load(f)

generated = copy.deepcopy(inventory)
children = generated["all"]["children"]

for group_name in ("masters", "workers"):
    inventory_group = {
        "masters": "k8s_masters",
        "workers": "k8s_workers",
    }[group_name]

    hosts = children[inventory_group]["hosts"]

    for hostname, ip in ips[group_name].items():
        if hostname not in hosts:
            raise ValueError(f"Machine inconnue dans l'inventaire : {hostname}")
        hosts[hostname]["ansible_host"] = ip

minio_hosts = children["minio"]["hosts"]
for hostname, ip in ips["minio"].items():
    if hostname not in minio_hosts:
        raise ValueError(f"Machine inconnue dans l'inventaire : {hostname}")
    minio_hosts[hostname]["ansible_host"] = ip

with open("inventory.generated.yml", "w") as f:
    yaml.safe_dump(generated, f, sort_keys=False)