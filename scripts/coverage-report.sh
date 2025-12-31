#!/bin/sh

set -eu

ARTIFACT_DIR=${ARTIFACT_DIR:-tests/artifacts}
mkdir -p "$ARTIFACT_DIR"

# Sanity check: ensure we're using the venv Python
python -c "import sys; assert '/opt/venv' in sys.prefix"

# Reset coverage data
coverage erase

# Run Behave with coverage
coverage run --source=. -m behave tests/features

# Generate reports
coverage report -m | tee "$ARTIFACT_DIR/coverage.txt"
coverage xml -o "$ARTIFACT_DIR/coverage.xml"

echo "✅ Coverage artifacts generated in $ARTIFACT_DIR"
