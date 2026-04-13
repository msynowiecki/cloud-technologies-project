#!/bin/bash
set -euo pipefail

echo "==> Docker named volumes info"
echo ""

docker volume ls -q | while read -r vol; do
  echo "Volume: $vol"

  MOUNTPOINT=$(docker volume inspect "$vol" -f '{{.Mountpoint}}')
  echo "Path: $MOUNTPOINT"

  SIZE=$(du -sh "$MOUNTPOINT" 2>/dev/null | cut -f1 || echo "N/A")
  echo "Size: $SIZE"

  CONTAINERS=$(docker ps -a --filter volume="$vol" --format "{{.Names}}")

  echo "Containers:"
  if [[ -z "$CONTAINERS" ]]; then
    echo "-"
  else
    echo "$CONTAINERS"
  fi

  echo "------------------------"
done