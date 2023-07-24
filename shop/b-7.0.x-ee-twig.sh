#!/bin/bash

SCRIPT_PATH=$(dirname ${BASH_SOURCE[0]})

cd $SCRIPT_PATH/../../../ || exit

# Prepare services configuration
make setup
make addbasicservices
make file=services/adminer.yml addservice
make file=services/selenium-chrome.yml addservice
make file=services/node.yml addservice

$SCRIPT_PATH/../parts/b-7.0.x/start_shop.sh -eEE
$SCRIPT_PATH/../parts/b-7.0.x/require_twig_components.sh -eEE -ttwig

# Require demodata package
docker-compose exec -T \
  php composer config repositories.oxid-esales/oxideshop-demodata-ee \
  --json '{"type":"git", "url":"https://github.com/OXID-eSales/oxideshop_demodata_ee"}'
docker-compose exec -T php composer require oxid-esales/oxideshop-demodata-ee:dev-b-7.0.x --no-update

# Install all preconfigured dependencies
docker-compose exec -T php composer update --no-interaction

$SCRIPT_PATH/../parts/b-7.0.x/reset_database.sh -eEE
docker-compose exec -T php bin/oe-console oe:setup:demodata

docker-compose exec -T php bin/oe-console oe:theme:activate twig
$SCRIPT_PATH/../../parts/shared/create_admin.sh

echo "Done!"
