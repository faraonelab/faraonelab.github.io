#! /bin/bash
set -euo pipefail

# Create a new people entry in /people/<lastname>-<firstname>/index.qmd
# Prompts for: publishing name, lastname, firstname, position option -> subtitle + people_group, email, degrees, optional headshot
# Copies headshot into the person's folder as headshot.<ext>
# Opens the new file in Positron if available (otherwise prints the path)

# get inputs
read -p "Enter publishing name (e.g., Jane Smith): " pub_name
read -p "Enter lastname (e.g., Smith): " lastname
read -p "Enter firstname (e.g., Jane): " firstname

# position -> subtitle, and group -> people_group
echo ""
echo "Choose a position for the person (this sets BOTH subtitle and people_group):"
echo "1. Principal Investigator (PI)"
echo "2. Postdoctoral Fellow"
echo "3. Graduate Student, Chemistry"
echo "4. Graduate Student, Biology"
echo "5. Honours Student"
echo "6. Research Assistant"
echo "7. Research Scientist"
echo "8. Alumni"
echo "9. Other (you will type subtitle + people_group)"
echo "0. Skip position (you will type people_group; subtitle left blank)"
read -p "Enter your choice: " position_option

position=""
group=""

case $position_option in
  1)
    position="Principal Investigator"
    group="pi"
    ;;
  2)
    position="Postdoctoral Fellow"
    group="postdoc"
    ;;
  3)
    position="Graduate Student, Chemistry"
    group="gradstudent"
    ;;
  4)
    position="Graduate Student, Biology"
    group="gradstudent"
    ;;
  5)
    position="Honours Student"
    group="honoursstudent"
    ;;
  6)
    position="Research Assistant"
    group="assistant"
    ;;
  7)
    position="Research Scientist"
    group="researcher"
    ;;
  8)
    position="Alumni"
    group="alumni"
    ;;
  9)
    read -p "Enter subtitle/position (e.g., Visiting Scholar): " position
    read -p "Enter people_group (pi | researcher | postdoc | gradstudent | honoursstudent | assistant | alumni): " group
    ;;
  0)
    position=""
    read -p "Enter people_group (pi | researcher | postdoc | gradstudent | honoursstudent | assistant | alumni): " group
    ;;
  *)
    echo "Invalid choice. Exiting..." >&2
    exit 1
    ;;
esac

# email
read -p "Enter email (or leave blank): " email

# degrees
read -p "Enter the number of degrees (0 if none): " num_degrees

degrees_string=""
if [[ "$num_degrees" -gt 0 ]]; then
  degrees=()
  institutions=()

  for ((i=0; i<num_degrees; i++)); do
    read -p "Enter degree $((i+1)) (e.g., PhD): " degree
    read -p "Enter institution $((i+1)) (e.g., Acadia University): " institution
    degrees+=("$degree")
    institutions+=("$institution")
  done

  for ((i=0; i<num_degrees; i++)); do
    degrees_string+="${degrees[$i]} | ${institutions[$i]}"
    if (( i < num_degrees - 1 )); then
      degrees_string+=" <br> "
    fi
  done
else
  degrees_string=""
fi

# folder name: lastname-firstname in lowercase, spaces -> hyphens
foldername=$(echo "$lastname-$firstname" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' )
person_dir="people/${foldername}"
mkdir -p "$person_dir"

# OPTIONAL HEADSHOT
read -p "Enter path to headshot image (optional, press Enter to skip): " image_path

image_filename=""
# You said you want avatar in each folder:
# Default stays as avatar.jpg (you can add it to the folder whenever you want).
image_yaml="\"avatar.jpg\""

if [[ -n "${image_path}" ]]; then
  if [[ ! -f "${image_path}" ]]; then
    echo "Image file not found: ${image_path}" >&2
    echo "Continuing with avatar.jpg..."
  else
    ext="${image_path##*.}"
    ext="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"
    image_filename="headshot.${ext}"
    cp "${image_path}" "${person_dir}/${image_filename}"
    image_yaml="\"${image_filename}\""
    echo "Copied image to: ${person_dir}/${image_filename}"
  fi
fi

# write index.qmd
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

## {{< meta first >}}'s Group Publications

:::{#pubs}
:::
EOF

# open the new index.qmd file in Positron if available
if command -v positron >/dev/null 2>&1; then
  positron "${person_dir}/index.qmd"
else
  echo "Positron not found. Open this file manually:"
  echo "${person_dir}/index.qmd"
fi

echo "New people entry created at: ${person_dir}/index.qmd"
if [[ -z "${image_filename}" ]]; then
  echo "No headshot copied. Using avatar.jpg (make sure it exists in: ${person_dir}/avatar.jpg)."
fi
