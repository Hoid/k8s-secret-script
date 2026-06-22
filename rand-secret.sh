#!/usr/bin/env bash
set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

info()    { printf "  ${CYAN}%s${NC}\n" "$*"; }
success() { printf "  ${GREEN}✓ %s${NC}\n" "$*"; }
warn()    { printf "${YELLOW}%s${NC}\n" "$*"; }
err()     { printf "${RED}Error: %s${NC}\n" "$*" >&2; exit 1; }

printf "\n${BOLD}=== Kubernetes Secret Creator ===${NC}\n\n"

# --- Secret name ---
read -rp "Secret name: " secret_name
[[ -z "$secret_name" ]] && err "Secret name cannot be empty."

# --- Namespace (optional) ---
read -rp "Namespace (blank = current context default): " namespace

printf "\n"
warn "Enter key-value pairs. Leave key blank when done."
warn "For a value, enter '?' to auto-generate a random alphanumeric string."
printf "\n"

declare -a literal_args=()
declare -a key_summary=()

while true; do
  read -rp "  Key (or Enter to finish): " key
  [[ -z "$key" ]] && break

  if ! [[ "$key" =~ ^[-._a-zA-Z0-9]+$ ]]; then
    warn "  Invalid key '${key}' — only alphanumeric characters, hyphens, underscores, and dots are allowed."
    printf "\n"
    continue
  fi

  # -s suppresses echoing — good practice for secrets
  read -rsp "  Value for '${key}' (or '?' for random): " value
  printf "\n"

  if [[ "$value" == "?" ]]; then
    read -rp "    Length [32]: " length_input
    length="${length_input:-32}"
    if ! [[ "$length" =~ ^[0-9]+$ ]] || [[ "$length" -eq 0 ]]; then
      err "Length must be a positive integer."
    fi

    # set +o pipefail in the subshell prevents head's SIGPIPE from
    # propagating as a non-zero exit when the pipeline is cut short
    value=$(set +o pipefail; cat /dev/urandom | base64 | tr -dc '0-9a-zA-Z' | head -c "$length")
    key_summary+=("${key} [random, ${length} chars]")
    success "Random ${length}-char value generated for '${key}'"
  else
    key_summary+=("${key} [provided]")
    info "Value recorded for '${key}'"
  fi

  literal_args+=("--from-literal=${key}=${value}")
  printf "\n"
done

[[ ${#literal_args[@]} -eq 0 ]] && err "No key-value pairs entered."

# --- Summary ---
printf "\n${BOLD}Summary${NC}\n"
printf "  Secret    : %s\n" "$secret_name"
printf "  Namespace : %s\n" "${namespace:-<current context default>}"
printf "  Keys:\n"
for entry in "${key_summary[@]}"; do
  printf "    - %s\n" "$entry"
done
printf "\n"

read -rp "Create this secret? [y/N] " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  warn "Aborted."
  exit 0
fi

printf "\n"

if [[ -n "$namespace" ]]; then
  kubectl create secret generic "$secret_name" \
    --namespace="$namespace" \
    "${literal_args[@]}"
else
  kubectl create secret generic "$secret_name" \
    "${literal_args[@]}"
fi

printf "\n"
success "Secret '${secret_name}' created successfully."
printf "\n"
