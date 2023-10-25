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

echo -e "\033[1;37m\033[1;42mRequire Deprecated tests package: Edition: ${edition}, Branch: ${branch}\033[0m\n"

if [ -z ${edition+x} ] || [ -z ${branch+x} ]; then
  echo -e "\e[1;31mThe edition (-e) and branch (-b) are required for require_deprecated_tests_bundle.sh\e[0m"
  exit 1
fi

docker compose exec php composer require oxid-esales/tests-deprecated-ce:dev-${branch} --with-all-dependencies --no-update

if [ $edition = "PE" ] || [ $edition = "EE" ]; then
  docker compose exec php composer config repositories.oxid-esales/tests-deprecated-pe git https://github.com/OXID-eSales/tests-deprecated-pe.git
  docker compose exec php composer require oxid-esales/tests-deprecated-pe:dev-${branch} --with-all-dependencies --no-update
fi

if [ $edition = "EE" ]; then
  docker compose exec php composer config repositories.oxid-esales/tests-deprecated-ee git https://github.com/OXID-eSales/tests-deprecated-ee.git
  docker compose exec php composer require oxid-esales/tests-deprecated-ee:dev-${branch} --with-all-dependencies --no-update
fi
