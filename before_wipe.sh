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
while IFS=: read -r user _ user_uid user_gid _ home shell; do
  # Apenas usuários humanos
  [[ "$user_uid" -lt 1000 ]] && continue
  [[ "$shell" == */nologin ]] && continue

  # Grupos (não pode falhar o script inteiro)
  groups=$(id -nG "$user" 2>/dev/null | tr ' ' ',' || true)

  echo "$user:$user_uid:$user_gid:$home:$shell:$groups" >> "$OUTPUT"
done < <(getent passwd)

echo "Snapshot criado em: $OUTPUT"
