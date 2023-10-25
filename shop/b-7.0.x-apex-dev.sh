#!/bin/bash

# Flags possible:
# -e for shop edition. Possible values: CE/PE/EE

edition='EE'
while getopts e: flag; do
  case "${flag}" in
  e) edition=${OPTARG} ;;
  *) ;;
  esac
done

SCRIPT_PATH=$(dirname ${BASH_SOURCE[0]})
cd $SCRIPT_PATH/../../../ || exit

# Prepare services configuration
make setup
make addbasicservices
make file=services/adminer.yml addservice
make file=services/selenium-chrome.yml addservice
make file=services/node.yml addservice

"${SCRIPT_PATH}/../parts/b-7.0.x/start_shop.sh" -e"${edition}" -u"false"
"${SCRIPT_PATH}/../parts/shared/require_twig_components.sh" -e"${edition}" -b"b-7.0.x"

"${SCRIPT_PATH}/../parts/shared/require_theme_dev.sh" -t"apex" -b"b-7.0.x"

"${SCRIPT_PATH}/../parts/shared/require_deprecated_tests_bundle.sh" -e"${edition}" -b"b-7.0.x"
"${SCRIPT_PATH}/../parts/shared/require_demodata_package.sh" -e"${edition}" -b"b-7.0.x"

# Install all preconfigured dependencies
docker compose exec -T php composer update --no-interaction

# Setup the database
"${SCRIPT_PATH}/../parts/shared/setup_database.sh"

docker compose exec -T php bin/oe-console oe:theme:activate apex
"${SCRIPT_PATH}/../parts/shared/create_admin.sh"

# Install old testing library config required for running old tests
cp source/vendor/oxid-esales/testing-library/test_config.yml.dist source/test_config.yml

echo "Done!"
