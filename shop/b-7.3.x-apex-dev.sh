#!/bin/bash

# Flags possible:
# -e for shop edition. Possible values: CE/PE/EE

branch='b-7.3.x'
edition='CE'
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

# Configure containers
perl -pi\
  -e 's#error_reporting = .*#error_reporting = E_ALL ^ E_WARNING ^ E_DEPRECATED#g;'\
  containers/php/custom.ini

"${SCRIPT_PATH}/../parts/shared/prepare_shop_package.sh" -e"${edition}" -b"${branch}"
"${SCRIPT_PATH}/../parts/shared/require_twig_components.sh" -e"${edition}" -b"${branch}"

"${SCRIPT_PATH}/../parts/shared/require_theme_dev.sh" -t"apex" -b"${branch}"

"${SCRIPT_PATH}/../parts/shared/require_demodata_package.sh" -e"${edition}" -b"${branch}"

# Install all preconfigured dependencies
docker compose exec -T php composer update --no-interaction

# Setup the database
"${SCRIPT_PATH}/../parts/shared/setup_database.sh"

docker compose exec -T php bin/oe-console oe:theme:activate apex
"${SCRIPT_PATH}/../parts/shared/create_admin.sh"

echo "Done!"

# after tests were executed sometimes reseting the db or cache is needed
# afterwards
# unit tests: test --testsuite Unit
# integration tests: test --testsuite Integration
# codeception tests: SELENIUM_SERVER_HOST=selenium BROWSER_NAME=chrome THEME_ID=apex vendor/bin/codecept run -c tests/codeception.yml -g xyz
# can be executed