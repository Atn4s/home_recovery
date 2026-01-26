#!/bin/bash

set -euo pipefail

HOME_BASE="/home"
SNAPSHOT="users.snapshot"

# Root check
if [[ $EUID -ne 0 ]]; then
  echo "Execute como root."
  exit 1
fi

# Dependência
if ! command -v whiptail &>/dev/null; then
  echo "whiptail não instalado."
  exit 1
fi

# Snapshot existe?
if [[ ! -f "$SNAPSHOT" ]]; then
  echo "Arquivo $SNAPSHOT não encontrado."
  exit 1
fi

# Monta lista para menu
USERS=()

while IFS=: read -r user uid gid home shell groups; do
  [[ "$user" =~ ^# ]] && continue
  [[ -d "$home" ]] || continue
  USERS+=("$user" "UID:$uid GID:$gid" OFF)
done < "$SNAPSHOT"

if [[ ${#USERS[@]} -eq 0 ]]; then
  whiptail --msgbox "Nenhum usuário válido encontrado." 10 50
  exit 0
fi

# Menu interativo
SELECTED=$(whiptail --title "Restauração de Usuários" \
  --checklist "Selecione os usuários a restaurar:" 20 70 10 \
  "${USERS[@]}" 3>&1 1>&2 2>&3)

[[ -z "$SELECTED" ]] && exit 0

# Senha padrão
PASSWORD=$(whiptail --passwordbox "Digite a senha padrão:" 10 60 3>&1 1>&2 2>&3)
[[ -z "$PASSWORD" ]] && exit 1

read -r -a SELECTED_USERS <<< "$SELECTED"

clear
echo "Restaurando usuários..."
echo

for raw in "${SELECTED_USERS[@]}"; do
  USER="${raw//\"/}"

  LINE=$(grep "^$USER:" "$SNAPSHOT")
  [[ -z "$LINE" ]] && continue

  IFS=: read -r \
    SNAP_USER \
    USER_UID \
    USER_GID \
    USER_HOME \
    USER_SHELL \
    USER_GROUPS <<< "$LINE"

  # Se já existir, pula (proteção)
  if id "$SNAP_USER" &>/dev/null; then
    echo "⚠ Usuário $SNAP_USER já existe. Pulando."
    continue
  fi

  # Garante grupo primário com GID correto
  if ! getent group "$USER_GID" &>/dev/null; then
    groupadd -g "$USER_GID" "$SNAP_USER"
  fi

  # Cria usuário preservando UID/GID
  useradd \
    -u "$USER_UID" \
    -g "$USER_GID" \
    -d "$USER_HOME" \
    -s "$USER_SHELL" \
    -M \
    "$SNAP_USER"

  # Grupos secundários
  IFS=',' read -ra GRPS <<< "$USER_GROUPS"
  for g in "${GRPS[@]}"; do
    [[ "$g" == "$SNAP_USER" ]] && continue
    getent group "$g" &>/dev/null && usermod -aG "$g" "$SNAP_USER"
  done

  # Senha padrão (não força troca)
  echo "$SNAP_USER:$PASSWORD" | chpasswd

  # Corrige ownership do /home
  chown -R "$USER_UID:$USER_GID" "$USER_HOME"

  echo "✔ Usuário $SNAP_USER restaurado (UID $USER_UID)."
done

echo
echo "Restauração concluída com sucesso."
