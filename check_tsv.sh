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

    # Count the number of columns in the header
    local num_columns=$(echo "$header" | awk -F'\t' '{print NF}')
    
    # Initialize line number
    local line_number=1

    # Read through the file line by line
    while IFS= read -r line; do
        # Increment line number
        ((line_number++))

        # Count the number of columns in the current line
        local num_columns_line=$(echo "$line" | awk -F'\t' '{print NF}')

        # Check if the number of columns matches the header
        if [[ "$num_columns_line" -ne "$num_columns" ]]; then
            echo "Line $line_number in $file does not have the same number of cells as the header." >&2
        fi
    done < "$file"
}

# Iterate over all input files
for file in "$@"; do
    if [[ -f "$file" ]]; then
        check_tsv "$file"
    else
        echo "$file does not exist." >&2
    fi
done
