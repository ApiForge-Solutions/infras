# 1. Installer pipx via apt (Ubuntu 24.04 + Debian 13 ont pipx natif)
sudo apt update
sudo apt install -y pipx
pipx ensurepath
exec $SHELL

# 2. Installer ansible
pipx install --include-deps ansible

# 3. Vérifier
ansible --version