#!/usr/bin/env bash
set -euo pipefail

# 1) Require a --config argument
if [ $# -eq 0 ] || [[ "$1" != --config=* ]]; then
  echo "❌  Error: you must pass --config=/path/to/odoo.conf" >&2
  echo "    Usage: $0 --config=/path/to/odoo.conf [other Odoo args]" >&2
  exit 1
fi

# 2) Run Odoo
cd /opt/odoo
exec python3 ./odoo-bin "$@"
