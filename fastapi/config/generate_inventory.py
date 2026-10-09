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
for hostname, ip in ips[group].items():
children[target]["hosts"][hostname]["ansible_host"] = ip

with open("inventory.generated.yml", "w", encoding="utf-8") as f:
yaml.safe_dump(generated, f, sort_keys=False, allow_unicode=True)
