#!/bin/bash
# Definição do pipefail para capturar erros.
set -euo pipefail

# ==================================================
# CONFIGURAÇÕES
# ==================================================

APT_PACKAGES=(
    build-essential git gparted gsmartcontrol 
    htop openjdk-25-jdk openssh-server
    python3-pip python3-venv python3-tk
    ranger tmux vlc 
)

# ==================================================
# Funções Auxiliares
# ==================================================
msg() {
    echo -e "\e[1;32m> $1\e[0m"
}

warn() {
    echo -e "\e[1;33m⚠ $1\e[0m"
}

# ==================================================
# Funções
# ==================================================
header(){
    clear
    echo -e "\e[1;34m"
    cat <<'EOF'
__  __     __  __ _____ _   _   __  __            _     _                 
\ \/ /    |  \/  | ____| \ | | |  \/  | __ _  ___| |__ (_)_ __   ___  ___ 
 \  /_____| |\/| |  _| |  \| | | |\/| |/ _` |/ __| '_ \| | '_ \ / _ \/ __|
 /  \_____| |  | | |___| |\  |_| |  | | (_| | (__| | | | | | | |  __/\__ \
/_/\_\    |_|  |_|_____|_| \_(_)_|  |_|\__,_|\___|_| |_|_|_| |_|\___||___/                                                                        
EOF
    echo -e "\e[0m"                                                                   
}

# Atualização e Upgrade de pacotes
update_system(){
    msg "Atualizando sistema"
    sudo apt update 
    sudo apt upgrade -y     
}

#Instalação de pacotes APT
install_apt_packages(){
    msg "Instalando pacotes APT"
    sudo apt install -y "${APT_PACKAGES[@]}"    
}

#Limpeza
clean(){
  sudo apt autoremove -y
}

# ==================================================
# EXECUÇÃO
# ==================================================
header
update_system
install_apt_packages    
clean

msg "Sistema pronto para uso"
