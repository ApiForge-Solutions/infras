# Install pipx via apt
sudo apt update
sudo apt install -y pipx
pipx ensurepath
exec $SHELL

# Install ansible
pipx install --include-deps ansible

# Install Lint
pipx install ansible-lint

# Check
ansible --version
ansible-lint --version
