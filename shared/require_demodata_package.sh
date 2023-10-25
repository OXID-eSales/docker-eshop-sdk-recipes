#!/bin/bash

# Flags possible:
# -e for shop edition. Possible values: CE/PE/EE
# -b branch of deprecated tests repositories

while getopts e:b:u: flag; do
  case "${flag}" in
  e) edition=${OPTARG} ;;
  b) branch=${OPTARG} ;;
  *) ;;
  esac
done

echo -e "\033[1;37m\033[1;42mRequire demodata package: Edition: ${edition}, Branch: ${branch}\033[0m\n"

if [ -z ${edition+x} ] || [ -z ${branch+x} ]; then
  echo -e "\e[1;31mThe edition (-e) and branch (-b) are required for require_demodata_package.sh\e[0m"
  exit 1
fi

if [ $edition = "CE" ]; then
  docker compose exec -T \
    php composer config repositories.oxid-esales/oxideshop-demodata-ce \
    --json '{"type":"git", "url":"https://github.com/OXID-eSales/oxideshop_demodata_ce"}'
  docker compose exec -T php composer require oxid-esales/oxideshop-demodata-ce:dev-${branch} --no-update
fi

if [ $edition = "PE" ]; then
  docker compose exec -T \
    php composer config repositories.oxid-esales/oxideshop-demodata-pe \
    --json '{"type":"git", "url":"https://github.com/OXID-eSales/oxideshop_demodata_pe"}'
  docker compose exec -T php composer require oxid-esales/oxideshop-demodata-pe:dev-${branch} --no-update
fi


if [ $edition = "EE" ]; then
  docker compose exec -T \
    php composer config repositories.oxid-esales/oxideshop-demodata-ee \
    --json '{"type":"git", "url":"https://github.com/OXID-eSales/oxideshop_demodata_ee"}'
  docker compose exec -T php composer require oxid-esales/oxideshop-demodata-ee:dev-${branch} --no-update
fi
