#!/usr/bin/env bash
# Update one or more Odoo modules on a chosen database, via docker compose.
#
# Safety first: the running 'odoo' container is stopped before the update
# runs (so it's never mid-request while the schema changes), the update
# itself runs in a throwaway container, and the 'odoo' container is always
# started back up afterwards - even if the update fails or the script is
# interrupted (Ctrl+C).
#
# Usage:
#   ./update-module.sh <database> <module1> [module2] [module3] ...
#
# No arguments:
#   Lists the available databases and shows usage.
#
# Service/user names default to this project's docker-compose.yml and can be
# overridden via environment variables, e.g.:
#   DB_SERVICE=db ODOO_SERVICE=web PG_USER=odoo ./update-module.sh mydb sale

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

DB_SERVICE="${DB_SERVICE:-psqlx}"
ODOO_SERVICE="${ODOO_SERVICE:-odoo}"
PG_USER="${PG_USER:-odoo}"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

print_usage() {
  cat <<EOF
Usage: $(basename "$0") <database> <module1> [module2] [module3] ...

  <database>   Nama database Odoo yang mau di-update
  <moduleN>    Satu atau lebih nama modul (technical name), dipisah spasi
               (atau koma dalam satu argumen, mis. "mod1,mod2")

Contoh:
  $(basename "$0") mydb sale
  $(basename "$0") mydb sale account stock
  $(basename "$0") mydb sale,account,stock

Tanpa argumen, script ini menampilkan daftar database yang ada.

Environment variable (opsional):
  DB_SERVICE     Nama service postgres di docker compose   (default: ${DB_SERVICE})
  ODOO_SERVICE   Nama service odoo di docker compose       (default: ${ODOO_SERVICE})
  PG_USER        User postgres                             (default: ${PG_USER})
EOF
}

require_docker_compose() {
  if ! docker compose version >/dev/null 2>&1; then
    echo "!! 'docker compose' tidak ditemukan. Pastikan Docker Compose v2 terinstall." >&2
    exit 1
  fi
}

list_databases() {
  echo "==> Daftar database:"
  docker compose exec -T "${DB_SERVICE}" psql -U "${PG_USER}" -d postgres -tAc \
    "SELECT datname FROM pg_database
     WHERE datname NOT IN ('postgres', 'template0', 'template1')
     ORDER BY datname" \
    | sed '/^$/d; s/^/  - /'
}

database_exists() {
  local db="$1"
  docker compose exec -T "${DB_SERVICE}" psql -U "${PG_USER}" -d postgres -tAc \
    "SELECT 1 FROM pg_database WHERE datname = '${db}'" | grep -q '^1$'
}

# ---------------------------------------------------------------------------
# Odoo container lifecycle
# ---------------------------------------------------------------------------

stop_odoo() {
  echo "==> Mematikan container '${ODOO_SERVICE}'..."
  docker compose stop "${ODOO_SERVICE}"
}

start_odoo() {
  echo "==> Menghidupkan lagi container '${ODOO_SERVICE}'..."
  docker compose start "${ODOO_SERVICE}"
}

# ---------------------------------------------------------------------------
# Update
# ---------------------------------------------------------------------------

run_module_update() {
  local db="$1"
  shift
  local modules_csv
  modules_csv="$(IFS=','; echo "$*")"

  echo "==> Update modul [${modules_csv}] pada database '${db}'..."
  # Tidak perlu menulis "/entrypoint.sh" di sini - ENTRYPOINT image odoo:20
  # sudah otomatis /entrypoint.sh, jadi command di bawah ini sudah cukup jadi
  # argumennya. Selain lebih ringkas, ini juga menghindari argumen berawalan
  # "/" yang bisa "dimangling" jadi path Windows oleh Git Bash/MSYS di Windows.
  docker compose run --rm "${ODOO_SERVICE}" \
    odoo -u "${modules_csv}" -d "${db}" --stop-after-init
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  require_docker_compose

  if [ "$#" -eq 0 ]; then
    list_databases
    echo
    print_usage
    exit 0
  fi

  if [ "$#" -lt 2 ]; then
    echo "!! Minimal harus ada nama database dan 1 nama modul." >&2
    echo >&2
    print_usage >&2
    exit 1
  fi

  local db="$1"
  shift
  local modules=("$@")

  if ! database_exists "${db}"; then
    echo "!! Database '${db}' tidak ditemukan." >&2
    echo >&2
    list_databases
    exit 1
  fi

  # Apapun hasilnya (sukses, gagal, atau di-Ctrl+C), container odoo harus
  # tetap hidup lagi di akhir.
  trap start_odoo EXIT

  stop_odoo
  run_module_update "${db}" "${modules[@]}"

  echo "==> Selesai. Modul [${modules[*]}] sudah di-update pada database '${db}'."
}

main "$@"
