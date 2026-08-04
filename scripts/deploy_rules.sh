#!/usr/bin/env bash
#
# deploy_rules.sh — copy Project000 custom rules into a Wazuh manager
# and restart the manager service so they take effect.
#
# Usage: ./deploy_rules.sh [WAZUH_RULES_DIR]
# Default WAZUH_RULES_DIR: /var/ossec/etc/rules

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="${1:-/var/ossec/etc/rules}"

if [ ! -d "$TARGET_DIR" ]; then
  echo "Target rules directory not found: $TARGET_DIR" >&2
  exit 1
fi

echo "Copying rules from $REPO_ROOT/rules to $TARGET_DIR ..."
cp -v "$REPO_ROOT"/rules/*.xml "$TARGET_DIR"/

echo "Restarting wazuh-manager ..."
systemctl restart wazuh-manager

echo "Done. Tail the log to confirm rules loaded cleanly:"
echo "  tail -f /var/ossec/logs/ossec.log"
