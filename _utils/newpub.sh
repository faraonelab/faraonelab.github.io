#!/bin/bash
set -euo pipefail

# Configuration
MAX_WORDS=4

# 1. Manually input the year
read -p "Enter the Publication Year (e.g., 2026): " year

# 2. Get the next publication number based on the entered year
last_pub=$(ls -d publications/${year}_* 2>/dev/null | grep -Eo '_[0-9]{3}_' | sed 's/_//g' | sort -n | tail -1 || echo "")

if [ -z "$last_pub" ]; then
    pub_number="001"
else
    # Increments the last found number by 1
    pub_number=$(printf "%03d" $((10#$last_pub + 1)))
fi

# 3. Mandatory Date Input (yyyy-mm-dd)
pub_date=""
while [[ ! $pub_date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; do
    read -p "Enter the Publish Date (yyyy-mm-dd) [Required]: " pub_date
    if [[ ! $pub_date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        echo ">> Error: Invalid format. Please use yyyy-mm-dd (e.g., $year-01-25)."
    elif [[ "$pub_date" != "$year"* ]]; then
        echo ">> Warning: The date ($pub_date) does not start with the year you entered ($year)."
        read -p "Are you sure? (y/n): " confirm
        [[ "$confirm" != "y" ]] && pub_date=""
    fi
done

# 4. General Inputs
read -p "Enter the FULL title of the publication: " title
read -p "Enter the authors (comma-separated): " authors
read -p "Enter Journal Name: " journal
read -p "Enter volume: " issue
read -p "Enter Pages: " page
read -p "Enter Source URL: " url_source
read -p "Enter Preprint URL: " url_preprint

# Auto-generate short title for folder
short_title=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-zA-Z0-9 ]//g' | cut -d' ' -f1-$MAX_WORDS | tr ' ' '_')

dir_name="publications/${year}_${pub_number}_${short_title}"
mkdir -p "$dir_name"

# Format authors for YAML array
authors_formatted=$(echo "$authors" | sed 's/ and / /g' | sed 's/,[ ]*/","/g' | sed 's/^/"/;s/$/"/')

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

# 5. Write index.qmd
cat <<EOF > "$dir_name/index.qmd"
---
title: "$title"
author: [$authors_formatted]
$( [[ -n "$category" ]] && echo "categories: [\"$category\"]" )
date: "$pub_date"
url_source: "$url_source"
url_preprint: "$url_preprint"
journ: "$journal"
issue: "$issue"
page: "$page"
year: $year
pub_number: "$pub_number"
image: "feature.png" # REMINDER: Add your image file to this folder and rename it to feature.png
---
EOF

# 6. Open File
if command -v positron &> /dev/null; then
    positron "$dir_name/index.qmd"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    open -a "Positron" "$dir_name/index.qmd" || open "$dir_name/index.qmd"
else
    echo "Success: Created $dir_name (Positron not found in PATH)"
fi

echo "----------------------------------------------------------------"
echo "✅ Success: Created $dir_name at $pub_date"
echo "⚠️  REMINDER: Do not forget to add the image file into the folder:"
echo "   $dir_name/"
echo "----------------------------------------------------------------"