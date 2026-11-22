#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
for check in verify-settings.sh verify-finder-target.sh verify-file-creation.sh verify-terminal-launcher.sh verify-localization.sh verify-finder-configuration.sh verify-finder-requests.sh verify-finder-prototype.sh verify-app-bundle.sh; do
  bash "Tests/$check"
done
python3 -m unittest discover -s Tests -p 'test_*.py'
