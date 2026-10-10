import copy
import json
import sys
from pathlib import Path

import yaml


BASE_DIR = Path(__file__).resolve().parent

INVENTORY_FILE = BASE_DIR / "inventory.yaml"
IPS_FILE = BASE_DIR / "ansible_inventory.json"
GENERATED_FILE = BASE_DIR / "inventory.generated.yaml"


def main():
    if not INVENTORY_FILE.is_file():
        sys.exit(f"ERREUR : fichier introuvable : {INVENTORY_FILE}")

    with INVENTORY_FILE.open(encoding="utf-8") as f:
        inventory = yaml.safe_load(f)

    if not isinstance(inventory, dict) or "all" not in inventory:
        sys.exit("ERREUR : inventory.yaml doit contenir un groupe 'all'.")

    generated = copy.deepcopy(inventory)
    children = generated["all"].setdefault("children", {})

    # Supprimer le groupe Proxmox s'il existe
    children.pop("proxmox", None)

    # Les IP de inventory.yaml servent de valeurs par défaut.
    # Si Terraform a fourni son JSON, ses valeurs les remplacent.
    if IPS_FILE.is_file():
        print("Utilisation des adresses IP fournies par Terraform.")

        with IPS_FILE.open(encoding="utf-8") as f:
            ips = json.load(f)

        for source_group, target_group in [
            ("masters", "k8s_masters"),
            ("workers", "k8s_workers"),
            ("minio", "minio"),
        ]:
            if source_group not in ips:
                sys.exit(
                    f"ERREUR : groupe '{source_group}' absent "
                    "de ansible_inventory.json."
                )

            if target_group not in children:
                sys.exit(
                    f"ERREUR : groupe '{target_group}' absent "
                    "de inventory.yaml."
                )

            hosts = children[target_group].setdefault("hosts", {})

            for hostname, ip in ips[source_group].items():
                hosts.setdefault(hostname, {})["ansible_host"] = ip
    else:
        print(
            "ansible_inventory.json absent : "
            "conservation des IP de inventory.yaml."
        )

    with GENERATED_FILE.open("w", encoding="utf-8") as f:
        yaml.safe_dump(
            generated,
            f,
            sort_keys=False,
            allow_unicode=True,
        )

    print(f"Inventaire généré : {GENERATED_FILE}")


if __name__ == "__main__":
    main()