#!/bin/bash

if [[ "$1" == "check" ]]; then
  update=0
elif [[ "$1" == "update" ]]; then
  update=1
else
  echo "::error::Either 'check' or 'update' must be provided as an argument"
  exit 1
fi

if [[ "$2" != "" ]]; then
  modified_files=$2
else
  modified_files=$(git diff HEAD --name-only | grep '.swift$')
fi

BASEDIR=$(dirname $0)
errors=0
current_year=$(date +"%Y")
header=$(cat LICENSE_HEADER)
cd ${BASEDIR}/..

for file in $modified_files; do
  if [[ $file == *.swift ]]; then
    if ! grep -q Copyright "$file"; then
      if [[ $update -eq 1 ]]; then
        echo "$(echo -e "$header\n"; cat $file)" > $file
        echo "Added license header in $file"
      else
        echo "::error::License header is missing in $file"
        ((errors++))
      fi
    fi
    if ! grep -q "$current_year" "$file"; then
      if [[ $update -eq 1 ]]; then
        created_year=$(git log --follow --format=%ad --date=format:'%Y' $file | tail -1)
        if [[ $current_year -eq $created_year ]]; then
          year="$current_year"
        else
          year="$created_year-$current_year"
        fi
        str="s/Copyright.*Pexip/Copyright $year Pexip/"
        if [[ "$OSTYPE" == "darwin"* ]]; then
          sed -i '' "$str" $file
        else
          sed -i "$str" $file
        fi
        git add "$file"
        echo "Updated license header in $file"
      else
        echo "::error::The year in license header must be updated in $file"
        ((errors++))
      fi
    fi
  fi
done

if [[ $errors -gt 0 ]]; then
  echo "License validation failed."
  exit 1
else
  echo "License validation succeeded."
fi
