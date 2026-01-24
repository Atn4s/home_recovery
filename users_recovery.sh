#!/bin/bash

set -euo pipefail

HOME_BASE="/home"
DEFAULT_SHELL="/bin/bash"

# Verifica se é root
if [[ $EUID -ne 0 ]]; then
  echo "Execute como root."
  exit 1
fi

# Verifica se whiptail existe
if ! command -v whiptail &>/dev/null; then
  echo "whiptail não está instalado."
  exit 1
fi

# Coleta diretórios em /home
USERS=()

for dir in "$HOME_BASE"/*; do
  [[ -d "$dir" ]] || continue

  user=$(basename "$dir")

  # Ignora diretórios de sistema
  [[ "$user" =~ ^(lost\+found|nobody|ftp|www-data)$ ]] && continue

  USERS+=("$user" "" OFF)
done

# Verifica se encontrou usuários
if [[ ${#USERS[@]} -eq 0 ]]; then
  whiptail --msgbox "Nenhum diretório válido encontrado em /home." 10 50
  exit 0
fi

# Menu interativo
SELECTED=$(whiptail --title "Criação de Usuários" \
  --checklist "Selecione os usuários a criar:" 20 60 ${#USERS[@]} \
  "${USERS[@]}" 3>&1 1>&2 2>&3)

[[ -z "$SELECTED" ]] && exit 0

# Senha padrão
PASSWORD=$(whiptail --passwordbox "Digite a senha padrão:" 10 60 3>&1 1>&2 2>&3)
[[ -z "$PASSWORD" ]] && exit 1

clear
echo "Recuperando usuários..."
echo

# Converte seleção em array (sem eval)
read -r -a SELECTED_USERS <<< "$SELECTED"

for user in "${SELECTED_USERS[@]}"; do
  user="${user//\"/}"

  if id "$user" &>/dev/null; then
    echo "⚠ Usuário $user já existe. Pulando."
    continue
  fi

  HOME_DIR="$HOME_BASE/$user"

  if [[ -d "$HOME_DIR" ]]; then
    # Cria usuário usando home existente e cria grupo primário
    useradd -U -d "$HOME_DIR" -s "$DEFAULT_SHELL" "$user"
    chown -R "$user:$user" "$HOME_DIR"
  else
    # Cria usuário com home nova
    useradd -U -m -s "$DEFAULT_SHELL" "$user"
  fi

  # Define senha (sem forçar troca)
  echo "$user:$PASSWORD" | chpasswd

  echo "✔ Usuário $user recuperado."
done

echo
echo "Processo finalizado."
