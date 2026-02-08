#! /bin/bash
set -euo pipefail

# Create a new people entry in /people/<lastname>-<firstname>/index.qmd
# Prompts for: name, lastname, firstname, position/group, email, degrees, optional image
# Copies image into the person's folder as headshot.<ext>
# Opens the new file in Positron

# get inputs
read -p "Enter publishing name: " pub_name
read -p "Enter lastname: " lastname
read -p "Enter firstname: " firstname

# get position from predefined list (aka subtitle)
echo "Choose a position for the person:"
echo "1. Postdoctoral Fellow"
echo "2. Graduate Student, Chemistry"
echo "3. Graduate Student, Biology"
echo "4. Honours Student"
echo "5. Research Assistant"
echo "6. Research Scientist"
echo "7. other"
echo "0. skip"
read -p "Enter your choice: " position_option

position=""
group=""

case $position_option in
  1)
    position="Postdoctoral Fellow"
    group="postdoc"
    ;;
  2)
    position="Graduate Student, Chemistry"
    group="gradstudent"
    ;;
  3)
    position="Graduate Student, Biology"
    group="gradstudent"
    ;;
  4)
    position="Honours Student"
    group="honoursstudent"
    ;;
  5)
    position="Research Assistant"
    group="assistant"
    ;;
  6)
    position="Research Scientist"
    group="researcher"
    ;;
  7)
    read -p "Enter position: " position
    read -p "Enter people group (e.g., pi | researcher | postdoc | gradstudent | honoursstudent | assistant | alumni): " group
    ;;
  0)
    position=""
    read -p "Enter people group (e.g., pi | researcher | postdoc | gradstudent | honoursstudent | assistant | alumni): " group
    ;;
  *)
    echo "Invalid choice. Exiting..." >&2
    exit 1
    ;;
esac

# email
read -p "Enter email: " email

# degrees
read -p "Enter the number of degrees: " num_degrees

degrees=()
institutions=()
degrees_string=""

for ((i=0; i<num_degrees; i++)); do
  read -p "Enter the degree $((i+1)): " degree
  read -p "Enter the institution $((i+1)): " institution
  degrees+=("$degree")
  institutions+=("$institution")
done

for ((i=0; i<num_degrees; i++)); do
  degrees_string+="${degrees[$i]} | ${institutions[$i]}"
  if (( i < num_degrees - 1 )); then
    degrees_string+=" <br> "
  fi
done

# folder name: lastname-firstname in lowercase, spaces -> hyphens
foldername=$(echo "$lastname-$firstname" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' )
person_dir="people/${foldername}"
mkdir -p "$person_dir"

# OPTIONAL IMAGE
read -p "Enter path to headshot image (optional, press Enter to skip): " image_path

image_filename=""
image_yaml="\"\""   # default empty string

if [[ -n "${image_path}" ]]; then
  if [[ ! -f "${image_path}" ]]; then
    echo "Image file not found: ${image_path}" >&2
    echo "Continuing without image..."
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

# open the new index.qmd file in Positron
positron "${person_dir}/index.qmd"

echo "New people entry created at: ${person_dir}/index.qmd"
if [[ -z "${image_filename}" ]]; then
  echo "No image copied. Your site will show the placeholder image until you add one."
fi
