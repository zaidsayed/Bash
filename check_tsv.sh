                                                                 

#!/bin/bash



# Define the correct filenames
declare -a correct_files=("gdp_vs_happiness.tsv" "homicide.tsv" "life_satisfaction.tsv")

# See if there are three files
if [ $# -ne 3 ]; then
    echo "Three files should be entered"
    exit 1
fi

# To check if correct file name has been entered
has_file() {
    local element
    for element in "${@:2}"; do
        [[ "$element" == "$1" ]] && return 0
    done
    return 1
}

# iterate through arguments
for file in "$@"; do
    if ! has_file "$file" "${correct_files[@]}"; then
        echo "Error: Wrong file name - $file"
        exit 1
    fi
done

 for file in "$1" "$2" "$3"; do
      if [ ! -s "$file" ]; then
          echo "Error: File '$file' is empty."
          exit 1
      fi
 done






# This function checks whether a file is tsv, removes continent column, deletes rows without a country code and only keep rows within the years 2011 to 2021
process_file() {

    local file="$1"
    local output_file="${file%.tsv}_cleaned.tsv"
    local header=$(head -n 1 "$file")

   


    # Finding the column number of continent
    local continent=$(echo "$header" | awk -F'\t' '{for (i=1; i<=NF; i++) if ($i == "Continent") print i}')

    # Count the number of columns in the header
    local num_columns=$(echo "$header" | awk -F'\t' '{print NF}')

    # Use awk to process the file - delete continent column, see if row has same number of cells as header
    awk -v num_columns="$num_columns" -v file="$file" -v continent="$continent" '
    BEGIN { FS="\t"; OFS="\t"; }
    NR == 1 {
        if (continent) {
            for (i=1; i<=NF; i++) {
                if (i != continent) {
                    printf "%s", $i
                    if (i < NF && i != continent - 1) printf "%s", OFS
                }
            }
            print ""
        } else {
            print
        }
    }
    NR > 1 && $2 != "" && $3 >= 2011 && $3 <= 2021 {
        if (continent) {
            if (NF != num_columns) {
                print "Line " NR " in " file " has different number of cells than that in the header." > "/dev/stderr";
            }
            for (i=1; i<=NF; i++) {
                if (i != continent) {
                    printf "%s", $i
                    if (i < NF && i != continent - 1) printf "%s", OFS
                }
            }
            print ""
        } else {
            if (NF != num_columns) {
                print "Line " NR " in " file " has different number of cells than that in the header." > "/dev/stderr";
            } else {
                print
            }
        }
    }' "$file" > "$output_file"
}



# Process each TSV file and store output filenames in variables
cleaned_file1=""
cleaned_file2=""
cleaned_file3=""

for file in "$@"; do
    if [[ -f "$file" ]]; then
        process_file "$file"
        case "$file" in
            *gdp_vs_happiness.tsv)
                cleaned_file1="${file%.tsv}_cleaned.tsv"
                ;;
            *homicide.tsv)
                cleaned_file2="${file%.tsv}_cleaned.tsv"
                ;;
            *life_satisfaction.tsv)
                cleaned_file3="${file%.tsv}_cleaned.tsv"
                ;;
        esac
    else
        echo "$file does not exist."
    fi
done


# The above code processed the individual files based on the requirements. The code below has logic for joining the processed tsv files.

     
OUTPUT_FILE="joined_file.tsv"
HEADER="Entity/Country\tCode\tYear\tGDP per capita\tPopulation\tHomicide Rate\tLife Expectancy\tCantril Ladder score"

# Sort the files based on 'Entity' and 'Year' columns
sort -k1,1 -k2,2 "$cleaned_file1" > sorted_gdp_vs_happiness.tsv
sort -k1,1 -k2,2 "$cleaned_file2" > sorted_homicide.tsv
sort -k1,1 -k2,2 "$cleaned_file3" > sorted_life_satisfaction.tsv

# Join the files based on 'Entity' and 'Year' columns
join -t $'\t' -1 1 -2 1 sorted_gdp_vs_happiness.tsv sorted_homicide.tsv | join -t $'\t' -1 1 -2 1 - sorted_life_satisfaction.tsv > temp_output.tsv



{
    echo -e "$HEADER"
    cat temp_output.tsv
} > "$OUTPUT_FILE"

# Clean up temporary files
rm sorted_gdp_vs_happiness.tsv sorted_homicide.tsv sorted_life_satisfaction.tsv temp_output.tsv 


# Input and output file paths
input_file=$OUTPUT_FILE
output_file="joined_file_filtered.tsv"

# Check if the input file exists
if [[ ! -f "$input_file" ]]; then
    echo "Input file not found!"
    exit 1
fi

# Process the file- of the joined rows, only want to take those rows with the same year
awk -F'\t' '{
    if ($3 == $8 && $8 == $11)
        print $0
}' "$input_file" > temp_filtered.tsv



 {
     echo -e "$HEADER"
     cat temp_filtered.tsv
 } > $output_file

rm temp_filtered.tsv

input="joined_file_filtered.tsv"
output="updated_joined_file_filtered.tsv"

# Remove specified columns (4, 7, 8, 10, 11, 14) as they are duplicates

awk -F'\t' 'BEGIN {OFS = FS} {
    $4 = $7 = $8 = $10 = $11 = $14 = ""
    gsub(/\t+/, "\t")
    print $0
}' "$input"  > temp_updated.tsv



 {
     echo -e "$HEADER"
     cat temp_updated.tsv
 } > "$output"


rm temp_updated.tsv


# last is the variable name of the final cleaned file

last="final_cleaned_data.tsv"

# Here I am sorting the column based on country code and removing an extra empty column at the end of the file.

{ head -n 1 "$output"; tail -n +2 "$output" | sort -t$'\t' -k2,2; } | cut -d $'\t' -f1-8  > "$last"

# The awk statement is to remove any additional headers that might have entered the file while using join command

awk 'NR==1 || $0 !~ /Code/' "$last" > temp && mv temp "$last"

cat $last


# Removing all the temporary files created
rm gdp_vs_happiness_cleaned.tsv homicide_cleaned.tsv life_satisfaction_cleaned.tsv joined_file.tsv joined_file_filtered.tsv updated_joined_file_filtered.tsv


rm final_cleaned_data.tsv











