#!/bin/bash

# Flags possible:
# -t for theme name. Possible values: apex, twig-admin, twig
# -b for theme repository branch

while getopts b:t:u: flag; do
  case "${flag}" in
  b) branch=${OPTARG} ;;
  t) theme=${OPTARG} ;;
  *) ;;
  esac
done

echo -e "\033[1;37m\033[1;42mRequire theme package (Not dev installation): Theme: ${theme}, Branch: ${branch}\033[0m\n"

if [ -z ${branch+x} ] || [ -z ${theme+x} ]; then
  echo -e "\e[1;31mThe theme (-t) and theme branch (-b) are required for require_theme.sh\e[0m"
  exit 1
fi

if [ $theme = "twig-admin" ]; then
  docker compose exec -T php composer require "oxid-esales/twig-admin-theme:dev-${branch}" --no-update
fi

# Prepare APEX theme
if [ $theme = "apex" ]; then
  docker compose exec -T php composer require "oxid-esales/apex-theme:dev-${branch}" --no-update
fi

# Prepare Twig theme
if [ $theme = "twig" ]; then
  docker compose exec -T php composer require "oxid-esales/twig-theme:dev-${branch}" --no-update
fi
