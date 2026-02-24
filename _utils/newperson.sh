#! /bin/bash
set -euo pipefail

# 1. Get ONLY the publishing name and email
read -p "Enter full publishing name (e.g., Jane M. Smith): " pub_name

# Logic to extract first and last name from pub_name
# First word = everything before the first space
firstname=$(echo "$pub_name" | awk '{print $1}')
# Last word = everything after the last space
lastname=$(echo "$pub_name" | awk '{print $NF}')

# Email validation - Cannot be blank
email=""
while [[ -z "$email" ]]; do
    read -p "Enter email [Required]: " email
    if [[ -z "$email" ]]; then
        echo ">> Error: Email is required."
    fi
done

# 2. Position selection
echo ""
echo "Choose a position for ${pub_name}:"
echo "1. Principal Investigator (PI)"
echo "2. Postdoctoral Fellow"
echo "3. Graduate Student, Chemistry"
echo "4. Graduate Student, Biology"
echo "5. Honours Student"
echo "6. Research Assistant"
echo "7. Research Scientist"
echo "8. Alumni"
echo "9. Other (manual entry)"
read -p "Enter your choice: " position_option

position=""
group=""

case $position_option in
  1) position="Principal Investigator"; group="pi" ;;
  2) position="Postdoctoral Fellow"; group="postdoc" ;;
  3) position="Graduate Student, Chemistry"; group="gradstudent" ;;
  4) position="Graduate Student, Biology"; group="gradstudent" ;;
  5) position="Honours Student"; group="honoursstudent" ;;
  6) position="Research Assistant"; group="assistant" ;;
  7) position="Research Scientist"; group="researcher" ;;
  8) position="Alumni"; group="alumni" ;;
  9) 
    read -p "Enter subtitle/position: " position
    read -p "Enter people_group (pi|researcher|postdoc|gradstudent|honoursstudent|assistant|alumni): " group 
    ;;
  *) echo "Invalid choice. Exiting..." >&2; exit 1 ;;
esac

# 3. Degrees
read -p "Enter the number of degrees (0 if none): " num_degrees
degrees_string=""
if [[ "$num_degrees" -gt 0 ]]; then
  for ((i=0; i<num_degrees; i++)); do
    read -p "Enter degree $((i+1)) (e.g., PhD): " degree
    read -p "Enter institution $((i+1)) (e.g., Acadia University): " institution
    [[ -n "$degrees_string" ]] && degrees_string+=" <br> "
    degrees_string+="${degree} | ${institution}"
  done
fi

# 4. Folder naming (based on the extracted names)
# Converts "Smith" and "Jane" to "smith-jane"
foldername=$(echo "${lastname}-${firstname}" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' )
person_dir="people/${foldername}"
mkdir -p "$person_dir"

# Default Image Logic
image_yaml="\"/images/avatar.jpg\""

# 5. Write index.qmd
cat > "${person_dir}/index.qmd" <<EOF
---
title: &TITLE "${pub_name}"
last: "${lastname}"
first: "${firstname}"
people_group: "${group}"
email: "${email}"
education:
  - "${degrees_string}"
subtitle: "${position}"
image: &IMAGE ${image_yaml}
page-layout: full

listing:
  id: pubs
  template: ../../_ejs/publications-people.ejs
  contents:
    - "../../../publications/**/*.qmd"
    - "!../../../publications/_template/"
  sort: "pub_number desc"
  filter-ui: true
  include:
    author: *TITLE
  fields: [publication, title, categories, image, date, author]

about:
  id: about
  template: trestles
  image-shape: round
  image: *IMAGE
  links:
    - icon: envelope
      text: Email
      href: mailto:${email}
---

<hr>

:::{#about}

## Education
{{< meta education >}}

:::
<br>

## {{< meta first >}}'s Publications

:::{#pubs}
:::
EOF

# 6. Open and Finish
if command -v positron >/dev/null 2>&1; then
  positron "${person_dir}/index.qmd"
else
  echo "File created at: ${person_dir}/index.qmd"
fi

echo "----------------------------------------------------------------"
echo "✅ Success: Created entry for ${pub_name}"
echo "📂 Folder: ${person_dir}"
echo "🖼️  IMAGE: Default set to /images/avatar.jpg"
echo "⚠️  REMINDER: To add a custom photo:"
echo "   1. Put photo in ${person_dir}/"
echo "   2. Update 'image:' in index.qmd"
echo "----------------------------------------------------------------"