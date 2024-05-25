#!/bin/bash

input_file="$1"
temp_data="temp_data.tsv"
correlation="correlation.tsv"

# Extract necessary columns
awk -F'\t' 'BEGIN {OFS="\t"}
    NR == 1 {
        for (i = 1; i <= NF; i++) {
            if ($i == "Entity/Country") country = i
            if ($i == "GDP per capita") gdp = i
            if ($i == "Population") population = i
            if ($i == "Homicide Rate") homicide = i
            if ($i == "Life Expectancy") life = i
            if ($i == "Cantril Ladder score") cantril = i
        }
    }
    NR > 1 && $cantril != "" && $gdp != "" && $population != "" && $homicide != "" && $life != "" {
        print $country, "GDP per capita", $gdp, $cantril
        print $country, "Population", $population, $cantril
        print $country, "Homicide Rate", $homicide, $cantril
        print $country, "Life Expectancy", $life, $cantril
    }
' "$input_file" > "$temp_data"

# Calculate correlations using concatenated keys
awk -F'\t' '{
    key = $1 FS $2; # Combine country and predictor
    count[key]++;
    sum_xy[key] += $3 * $4;
    sum_x[key] += $3;
    sum_y[key] += $4;
    sum_x2[key] += $3 * $3;
    sum_y2[key] += $4 * $4;
}
END {
    for (key in sum_xy) {
        if (count[key] >= 3) {
            n = count[key];
            sumxy = sum_xy[key];
            sumx = sum_x[key];
            sumy = sum_y[key];
            sumx2 = sum_x2[key];
            sumy2 = sum_y2[key];

            numerator = n * sumxy - sumx * sumy;
            denominator = sqrt((n * sumx2 - sumx * sumx) * (n * sumy2 - sumy * sumy));
            if (denominator != 0) {
                r = numerator / denominator;
                split(key, parts, FS);
                country = parts[1];
                predictor = parts[2];
                printf "%s\t%s\t%.3f\n", country, predictor, r;
            }
        }
    }
}' "$temp_data" > "$correlation"

# Summarize correlations across predictors and find the best predictor
awk -F'\t' '{
    mean[$2] += $3;
    count[$2] += 1;
}
END {
    max_corr = 0;
    max_predictor = "";
    for (predictor in mean) {
        if (count[predictor] > 0) {
            mean_corr = mean[predictor] / count[predictor];
            printf "Mean correlation of %s with Cantril ladder is %.3f\n", predictor, mean_corr;
            # Calculate the absolute value manually
            abs_mean_corr = mean_corr < 0 ? -mean_corr : mean_corr;
            if (abs_mean_corr > max_corr) {
                max_corr = abs_mean_corr;
                max_predictor = predictor;
            }
        }
    }
    printf "\nMost predictive mean correlation with the Cantril ladder is %s (r = %.3f)\n", max_predictor, max_corr;
}' "$correlation"

# Cleanup
rm "$temp_data" "$correlation"

