#!/bin/bash

# Configuration
MAX_WORDS=4

# 1. Manually input the year
read -p "Enter the Publication Year (e.g., 2026): " year

# 2. Get the next publication number based on the entered year
# We look specifically in the folder for THAT year
last_pub=$(ls -d publications/${year}_* 2>/dev/null | grep -Eo '_[0-9]{3}_' | sed 's/_//g' | sort -n | tail -1)

if [ -z "$last_pub" ]; then
    pub_number="001"
else
    # Increments the last found number by 1
    pub_number=$(printf "%03d" $((10#$last_pub + 1)))
fi

# Inputs
read -p "Enter the FULL title of the publication: " title
read -p "Enter the authors (comma-separated): " authors

# Auto-generate short title for folder
short_title=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-zA-Z0-9 ]//g' | cut -d' ' -f1-$MAX_WORDS | tr ' ' '_')

dir_name="publications/${year}_${pub_number}_${short_title}"
mkdir -p "$dir_name"

read -p "Enter Journal Name: " journal
read -p "Enter volume: " issue
read -p "Enter Pages: " page
read -p "Enter Source URL: " url_source
read -p "Enter Preprint URL: " url_preprint

# Format authors
authors_formatted=$(echo "$authors" | sed 's/ and / /g' | sed 's/,[ ]*/","/g' | sed 's/^/"/;s/$/"/')

# Category selection
# Category selection
echo -e "\nChoose a category:"
echo "1. Tick Chemical Ecology & Sensory Neurobiology"
echo "2. Tick Management"
echo "3. Psilocybin Research"
echo "0. Skip"
read -p "Choice: " cat_num

case $cat_num in
    1) category="chemical-ecology" ;;
    2) category="tick-management" ;;
    3) category="psilocybin" ;;
    *) category="" ;;
esac

# Write index.qmd
cat <<EOF > "$dir_name/index.qmd"
---
title: "$title"
author: [$authors_formatted]
$( [[ -n "$category" ]] && echo "categories: [\"$category\"]" )
url_source: "$url_source"
url_preprint: "$url_preprint"
journ: "$journal"
issue: "$issue"
page: "$page"
year: $year
pub_number: "$pub_number"
image: ""
---
EOF

# 3. Fixed Positron Call
# This uses 'open -a' for macOS or falls back to 'code' or 'open'
if command -v positron &> /dev/null; then
    positron "$dir_name/index.qmd"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # If on Mac and 'positron' isn't in PATH, try the App name
    open -a "Positron" "$dir_name/index.qmd" || open "$dir_name/index.qmd"
else
    echo "Success: Created $dir_name (Positron not found in PATH)"
fi

echo "Success: Created $dir_name"