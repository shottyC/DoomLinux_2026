#!/bin/sh

set -eu

ARTIFACT_DIR=${ARTIFACT_DIR:-tests/artifacts}

print_usage() {
	cat <<USAGE
Usage: $0 [summary-files...]

Converts emoji-rich summary tables into CSV and LaTeX outputs.
Without arguments, the script scans for "*-summary.txt" within
"$ARTIFACT_DIR".
USAGE
}

if [ "${1:-}" = "--help" ]; then
	print_usage
	exit 0
fi

if [ "$#" -gt 0 ]; then
	set -- "$@"
else
	set -- "$ARTIFACT_DIR"/*-summary.txt
fi

found=0

for summary in "$@"; do
	if [ ! -f "$summary" ]; then
		continue
	fi
	found=1
	base=${summary%.txt}
	csv="${base}.csv"
	tex="${base}.tex"

	python3 - "$summary" "$csv" "$tex" <<'PY'
import csv
import sys

summary_path, csv_path, tex_path = sys.argv[1:4]
rows = []

with open(summary_path, encoding="utf-8") as handle:
    for raw in handle:
        if "│" not in raw:
            continue
        parts = [segment.strip() for segment in raw.split("│")]
        if len(parts) < 3:
            continue
        field, value = parts[1], parts[2]
        if field and value and not field.startswith("┌"):
            rows.append((field, value))

with open(csv_path, "w", newline="", encoding="utf-8") as fh:
    writer = csv.writer(fh)
    writer.writerow(["Field", "Value"])
    writer.writerows(rows)

def escape_latex(text: str) -> str:
    replacements = {
        "\\": r"\\textbackslash{}",
        "&": r"\\&",
        "_": r"\\_",
        "#": r"\\#",
        "%": r"\\%",
        "$": r"\\$",
        "{": r"\\{",
        "}": r"\\}",
    }
    for old, new in replacements.items():
        text = text.replace(old, new)
    return text

with open(tex_path, "w", encoding="utf-8") as fh:
    fh.write("\\begin{tabular}{ll}\n")
    fh.write("\\hline\n")
    fh.write("Field & Value \\\\n")
    fh.write("\\hline\n")
    for field, value in rows:
        fh.write(f"{escape_latex(field)} & {escape_latex(value)} \\\\n")
    fh.write("\\hline\n\\end{tabular}\n")
PY

	printf '📊 Converted %s -> %s, %s\n' "$summary" "$csv" "$tex"
done

if [ "$found" -eq 0 ]; then
	echo "No summary files found to convert."
fi
