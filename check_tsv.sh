#!/bin/bash

# Function to check if a file is a TSV file based on the header, remove the "Continent" column, remove rows without a country code, and include only rows with years between 2011 to 2021
check_tsv() {
    local file="$1"
    local output_file="${file%.tsv}_processed.tsv"
    local header=$(head -n 1 "$file")

    if [[ "$header" == *$'\t'* ]]; then
        echo "$file is a TSV file."
    else
        echo "$file is not a TSV file."
    fi

    # Identify the column number for the "Continent" header
    local continent_col=$(echo "$header" | awk -F'\t' '{for (i=1; i<=NF; i++) if ($i == "Continent") print i}')

    # Count the number of columns in the header
    local num_columns=$(echo "$header" | awk -F'\t' '{print NF}')

    # Use awk to process the file
    awk -v num_columns="$num_columns" -v file="$file" -v continent_col="$continent_col" '
    BEGIN { FS="\t"; OFS="\t"; }
    NR == 1 {
        if (continent_col) {
            for (i=1; i<=NF; i++) {
                if (i != continent_col) {
                    printf "%s", $i
                    if (i < NF && i != continent_col - 1) printf "%s", OFS
                }
            }
            print ""
        } else {
            print
        }
    }
    NR > 1 && $2 != "" && $3 >= 2011 && $3 <= 2021 {
        if (continent_col) {
            if (NF != num_columns) {
                print "Line " NR " in " file " does not have the same number of cells as the header." > "/dev/stderr";
            }
            for (i=1; i<=NF; i++) {
                if (i != continent_col) {
                    printf "%s", $i
                    if (i < NF && i != continent_col - 1) printf "%s", OFS
                }
            }
            print ""
        } else {
            if (NF != num_columns) {
                print "Line " NR " in " file " does not have the same number of cells as the header." > "/dev/stderr";
            } else {
                print
            }
        }
    }' "$file" > "$output_file"
}

# Iterate over all input files
for file in "$@"; do
    if [[ -f "$file" ]]; then
        check_tsv "$file"
