#!/usr/bin/env bash
set -euo pipefail

case $# in
    0)
        input_dir=.
        output_dir=.
        ;;
    2)
        input_dir=$1
        output_dir=$2
        ;;
    *)
        echo "Usage: $0 [INPUT_DIRECTORY OUTPUT_DIRECTORY]" >&2
        exit 2
        ;;
esac

[[ -d "$input_dir" ]] || { echo "Input directory not found: $input_dir" >&2; exit 1; }
command -v spec2nii >/dev/null || { echo "spec2nii is not on PATH" >&2; exit 1; }

shopt -s nullglob
dat_files=("$input_dir"/*.dat)
(( ${#dat_files[@]} > 0 )) || { echo "No .dat files found in: $input_dir" >&2; exit 1; }

mkdir -p "$output_dir"

for dat_file in "${dat_files[@]}"; do
    stem=$(basename "$dat_file" .dat)
    twix_info=$(spec2nii twix -v "$dat_file")

    if [[ ! "$twix_info" =~ image.*Cha.*Set ]]; then
        echo "Unsupported image dimensions in: $dat_file" >&2
        printf '%s\n' "$twix_info" >&2
        exit 1
    fi

    dimensions=(-d5 Cha -t5 DIM_COIL -d6 Set -t6 DIM_DYN)
    if [[ "$twix_info" =~ image.*Eco ]]; then
        dimensions+=(-d7 Eco -t7 DIM_EDIT)
    fi

    echo "Converting $dat_file"
    spec2nii twix -e image --anon \
        "${dimensions[@]}" \
        -f "$stem" -o "$output_dir" "$dat_file"
done
