#!/bin/bash

# Flags possible:
# -e for edition. Possible values: CE/PE/EE
# -b for theme repository branch
# -d for dev environment (repo will be cloned)

while getopts e:b:d flag; do
  case "${flag}" in
  e) edition=${OPTARG} ;;
  b) branch=${OPTARG} ;;
  d) dev=1 ;;
  *) ;;
  esac
done

if [ -z ${edition+x} ] || [ -z ${branch+x} ]; then
  echo -e "\e[1;31mThe edition (-e) and branch (-b) are required for require_twig_components.sh\e[0m"
  exit 1
fi

echo -e "\033[1;37m\033[1;42mEdition: ${edition}, Branch: ${branch}, Dev: ${dev}\033[0m\n"

# Configure twig themes in composer
docker compose exec -T \
  php composer config repositories.oxid-esales/twig-component \
  --json '{"type":"git", "url":"https://github.com/OXID-eSales/twig-component"}'
docker compose exec -T php composer require oxid-esales/twig-component:dev-${branch} --no-update

if [ $edition = "PE" ] || [ $edition = "EE" ]; then
  docker compose exec -T \
    php composer config repositories.oxid-esales/twig-component-pe \
    --json '{"type":"git", "url":"https://github.com/OXID-eSales/twig-component-pe"}'
  docker compose exec -T php composer require oxid-esales/twig-component-pe:dev-${branch} --no-update
fi

if [ $edition = "EE" ]; then
  docker compose exec -T \
    php composer config repositories.oxid-esales/twig-component-ee \
    --json '{"type":"git", "url":"https://github.com/OXID-eSales/twig-component-ee"}'
  docker compose exec -T php composer require oxid-esales/twig-component-ee:dev-${branch} --no-update
fi

if [[ "$dev" -eq "1" ]]; then
  "$(dirname $0)/require_theme_dev.sh" -t"twig-admin" -b"${branch}"
else
  "$(dirname $0)/require_theme.sh" -t"twig-admin" -b"${branch}"
fi

