#!/bin/bash

# This function checks whether a file is tsv, removes continent column, deletes rows without a country code and only keep rows within the years 2011 to 2021

process_file() {
    local file="$1"
    local output_file="${file%.tsv}_processed.tsv"
    local header=$(head -n 1 "$file")

   


    # Finding the column number of continent
    local continent_col=$(echo "$header" | awk -F'\t' '{for (i=1; i<=NF; i++) if ($i == "Continent") print i}')

    # Count the number of columns in the header
    local num_columns=$(echo "$header" | awk -F'\t' '{print NF}')

    # Use awk to process the file - delete continent column, see if row has same number of cells as header
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



# Process each TSV file and store output filenames in variables
processed_file1=""
processed_file2=""
processed_file3=""

for file in "$@"; do
    if [[ -f "$file" ]]; then
        process_file "$file"
        case "$file" in
            *gdp_vs_happiness.tsv)
                processed_file1="${file%.tsv}_processed.tsv"
                ;;
            *homicide.tsv)
                processed_file2="${file%.tsv}_processed.tsv"
                ;;
            *life_satisfaction.tsv)
                processed_file3="${file%.tsv}_processed.tsv"
                ;;
        esac
    else
        echo "$file does not exist."
    fi
done


# The above code processed the individual files based on the requirements. The code below has logic for joining the processed tsv files.


OUTPUT_FILE="common_rows_output.tsv"
HEADER="Entity\tCode\tYear\tGDP per capita\tPopulation\tHomicide Rate\tLife Expectancy\tCantril Ladder score"

# Sort the files based on 'Entity' and 'Year' columns
sort -k1,1 -k2,2 "$processed_file1" > sorted_gdp_vs_happiness.tsv
sort -k1,1 -k2,2 "$processed_file2" > sorted_homicide.tsv
sort -k1,1 -k2,2 "$processed_file3" > sorted_life_satisfaction.tsv


# Join the files based on 'Entity' and 'Year' columns
join -t $'\t' -1 1 -2 1 sorted_gdp_vs_happiness.tsv sorted_homicide.tsv | join -t $'\t' -1 1 -2 1 - sorted_life_satisfaction.tsv > temp_output.tsv

#echo "$HEADER" > "$OUTPUT_FILE"
cat temp_output.tsv >> "$OUTPUT_FILE"

# Clean up temporary files
rm sorted_gdp_vs_happiness.tsv sorted_homicide.tsv sorted_life_satisfaction.tsv temp_output.tsv


# Input and output file paths
input_file=$OUTPUT_FILE
output_file="filtered_common_rows_output.tsv"

# Check if the input file exists
if [[ ! -f "$input_file" ]]; then
    echo "Input file not found!"
    exit 1
fi

# Process the file
awk -F'\t' '{
    if ($3 == $8 && $8 == $11)
        print $0
}' "$input_file" > temp_filtered.tsv

#echo "$HEADER" > "$output_file"
cat temp_filtered.tsv >> "$output_file"

rm temp_filtered.tsv

input="filtered_common_rows_output.tsv"
output="updated_filtered_common_rows_output.tsv"

# Remove specified columns (4, 7, 8, 10, 11, 14) as they are duplicates

awk -F'\t' 'BEGIN {OFS = FS} {
    $4 = $7 = $8 = $10 = $11 = $14 = ""
    gsub(/\t+/, "\t")
    print $0
}' "$input"  > temp_updated.tsv

echo "$HEADER" > "$output"
cat temp_updated.tsv >> "$output"

rm temp_updated.tsv

last="final_cleaned_data.tsv"

# Here I am sorting the column based on country code and removing an extra empty column at the end of the file.
{ head -n 1 "$output"; tail -n +2 "$output" | sort -t$'\t' -k2,2; } | cut -d $'\t' -f1-8  > "$last"

# This is to remove a row that is popping up in my output
sed -i '' '/Entity\tCode\tYear\t\"GDP per capita, PPP (constant 2017 international \$)\"\tPopulation (historical estimates)\t\"Homicide rate per 100,000 population - Both sexes - All ages\"\tLife expectancy - Sex: all - Age: at birth - Variant: estimates\tCantril ladder score/d' "$last"

cat $last
