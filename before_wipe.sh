#!/bin/bash

set -euo pipefail

OUTPUT="users.snapshot"

# Verifica root
if [[ $EUID -ne 0 ]]; then
  echo "Execute como root."
  exit 1
fi

echo "# username:uid:gid:home:shell:groups" > "$OUTPUT"

# Lista usuários reais (UID >= 1000)
getent passwd | awk -F: '$3 >= 1000 {print $1}' | while read -r user; do
  UID=$(id -u "$user")
  GID=$(id -g "$user")
  HOME=$(getent passwd "$user" | cut -d: -f6)
  SHELL=$(getent passwd "$user" | cut -d: -f7)
  GROUPS=$(id -nG "$user" | tr ' ' ',')

  echo "$user:$UID:$GID:$HOME:$SHELL:$GROUPS" >> "$OUTPUT"
done

echo "Snapshot criado em: $OUTPUT"