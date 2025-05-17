#!/usr/bin/env bash
set -euo pipefail
cd /opt/odoo

# always include the core Odoo addons:
ADDON_PATHS="/opt/odoo/addons"

# only append your extras if there’s at least one __init__.py under it
if find /mnt/extra-addons -mindepth 2 -maxdepth 2 -type f -name "__init__.py" | read; then
  ADDON_PATHS="$ADDON_PATHS,/mnt/extra-addons"
fi

exec python3 ./odoo-bin \
  --config=/configs/odoo.conf \
  --addons-path="$ADDON_PATHS" \
  --data-dir=/var/lib/odoo \
  "$@"
