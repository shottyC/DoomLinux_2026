#!/bin/sh

set -eu

ARTIFACT_DIR=${1:-tests/artifacts}
STATUS=0

if [ ! -d "$ARTIFACT_DIR" ]; then
    echo "No artifact directory found at $ARTIFACT_DIR"
    exit 0
fi

for logfile in "$ARTIFACT_DIR"/*.log; do
    if [ ! -f "$logfile" ]; then
        continue
    fi
    if grep -Eiq '(error|traceback|fail|panic)' "$logfile"; then
        echo "❌ Issues detected in $logfile"
        STATUS=1
    else
        echo "✅ Clean log: $logfile"
    fi
done

for summary in "$ARTIFACT_DIR"/*-summary.txt; do
    if [ ! -f "$summary" ]; then
        continue
    fi
    if ! grep -q '✅' "$summary"; then
        echo "⚠️ Summary missing ✅ indicator: $summary"
        STATUS=1
    else
        echo "✨ Summary sanity check passed: $summary"
    fi
done

exit "$STATUS"
