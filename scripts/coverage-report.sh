#!/bin/sh

set -eu

ARTIFACT_DIR=${ARTIFACT_DIR:-tests/artifacts}
mkdir -p "$ARTIFACT_DIR"

python3 -m pip install --user --upgrade coverage >/dev/null 2>&1 || true

python3 -m coverage erase
python3 -m coverage run --source=. -m behave tests/features
python3 -m coverage report -m | tee "$ARTIFACT_DIR/coverage.txt"
python3 -m coverage xml -o "$ARTIFACT_DIR/coverage.xml"

echo "✅ Coverage artifacts generated in $ARTIFACT_DIR"
