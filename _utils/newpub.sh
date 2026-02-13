#!/bin/bash

# Configuration
MAX_WORDS=4
year=$(date +%Y)

# Get the next publication number
last_pub=$(ls -d publications/* 2>/dev/null | grep -Eo '_[0-9]{3}_' | sed 's/_//g' | sort -n | tail -1)
if [ -z "$last_pub" ]; then
    pub_number="001"
else
    pub_number=$(printf "%03d" $((10#$last_pub + 1)))
fi

# Inputs
read -p "Enter the FULL title of the publication: " title
read -p "Enter the authors (comma-separated): " authors

# Auto-generate short title for folder (lowercase, no special chars, max words)
short_title=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-zA-Z0-9 ]//g' | cut -d' ' -f1-$MAX_WORDS | tr ' ' '_')

dir_name="publications/${year}_${pub_number}_${short_title}"
mkdir -p "$dir_name"

read -p "Enter Journal Name: " journal
read -p "Enter volume: " issue
read -p "Enter Pages: " page
read -p "Enter Source URL: " url_source
read -p "Enter Preprint URL: " url_preprint

# Format authors: removes 'and', trims space, wraps each in quotes
authors_formatted=$(echo "$authors" | sed 's/ and / /g' | sed 's/,[ ]*/","/g' | sed 's/^/"/;s/$/"/')

# Category selection
echo -e "\nChoose a category:"
echo "1. Fast electron nano-spectroscopy"
echo "2. Nanophotonics-quantum optics"
echo "3. Photothermal spectroscopy and microscopy"
echo "0. skip"
read -p "Choice: " cat_num

case $cat_num in
    1) category="fast_electron_nano-spectroscopy" ;;
    2) category="nanophotonics-quantum_optics" ;;
    3) category="photothermal_spectroscopy_and_microscopy" ;;
    *) category="" ;;
esac

# Write index.qmd
cat <<EOF > "$dir_name/index.qmd"
---
title: "$title"
author: [$authors_formatted]
categories: 
  - "$category"
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

# Open in Positron
positron "$dir_name/index.qmd"

echo "Success: Created $dir_name"