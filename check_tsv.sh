#!/bin/bash

# Function to check if a file is a TSV file based on the header
check_tsv() {
    local file="$1"
    local header=$(head -n 1 "$file")
    
    if [[ "$header" == *$'\t'* ]]; then
        echo "$file is a TSV file."
    else
        echo "$file is not a TSV file."
    fi
}

# Iterate over all input files
for file in "$@"; do
    if [[ -f "$file" ]]; then
        check_tsv "$file"
    else
        echo "$file does not exist."
    fi
done
