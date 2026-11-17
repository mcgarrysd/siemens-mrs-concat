#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 FILE_1.nii.gz FILE_2.nii.gz OUTPUT.nii.gz" >&2
    exit 2
fi

file_1=$1
file_2=$2
output=$3

[[ -f "$file_1" ]] || { echo "Input file not found: $file_1" >&2; exit 1; }
[[ -f "$file_2" ]] || { echo "Input file not found: $file_2" >&2; exit 1; }
[[ "$output" == *.nii.gz ]] || { echo "Output must end in .nii.gz: $output" >&2; exit 1; }
command -v mrs_tools >/dev/null || { echo "mrs_tools is not on PATH" >&2; exit 1; }

output_dir=$(dirname "$output")
output_name=$(basename "$output" .nii.gz)
mkdir -p "$output_dir"

mrs_tools merge \
    --files "$file_1" "$file_2" \
    --dim DIM_DYN \
    --output "$output_dir" \
    --filename "$output_name"

mrs_tools info "$output_dir/$output_name.nii.gz"
