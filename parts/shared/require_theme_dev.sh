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

echo -e "\033[1;37m\033[1;42mRequire theme package (Dev installation): Theme: ${theme}, Branch: ${branch}\033[0m\n"


if [ -z ${branch+x} ] || [ -z ${theme+x} ]; then
  echo -e "\e[1;31mThe theme (-t) and theme branch (-b) are required for require_theme.sh\e[0m"
  exit 1
fi

if [ $theme = "twig-admin" ]; then
  git clone https://github.com/OXID-eSales/twig-admin-theme --branch="$branch" source/source/Application/views/admin_twig
  docker compose exec -T \
    php composer config repositories.oxid-esales/twig-admin-theme \
    --json '{"type":"path", "url":"./source/Application/views/admin_twig", "options": {"symlink": false}}'
  docker compose exec -T php composer require oxid-esales/twig-admin-theme:* --no-update
  ln -s ../Application/views/admin_twig/out/admin_twig source/source/out/admin_twig
fi

# Prepare APEX theme
if [ $theme = "apex" ]; then
  git clone https://github.com/OXID-eSales/apex-theme.git --branch="$branch" source/source/Application/views/apex
  docker compose exec -T \
    php composer config repositories.oxid-esales/apex-theme \
    --json '{"type":"path", "url":"./source/Application/views/apex", "options": {"symlink": true}}'
  docker compose exec -T php composer require oxid-esales/apex-theme:* --no-update
  ln -s ../Application/views/apex/out/apex/ source/source/out/apex
fi

# Prepare Twig theme
if [ $theme = "twig" ]; then
  git clone https://github.com/OXID-eSales/twig-theme --branch="$branch" source/source/Application/views/twig
  docker compose exec -T \
    php composer config repositories.oxid-esales/twig-theme \
    --json '{"type":"path", "url":"./source/Application/views/twig", "options": {"symlink": false}}'
  docker compose exec -T php composer require oxid-esales/twig-theme:* --no-update
  ln -s ../Application/views/twig/out/twig/ source/source/out/twig
fi
