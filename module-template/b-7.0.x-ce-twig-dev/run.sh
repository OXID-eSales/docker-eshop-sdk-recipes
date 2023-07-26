#!/bin/bash

SCRIPT_PATH=$(dirname ${BASH_SOURCE[0]})

cd $SCRIPT_PATH/../../../../ || exit

# Prepare services configuration
make setup
make addbasicservices
make file=services/node.yml addservice
make file=services/selenium-chrome.yml addservice

perl -pi\
  -e 's#node:latest#node:12#g;'\
  docker-compose.yml

$SCRIPT_PATH/../../parts/b-7.0.x/start_shop.sh -eCE
$SCRIPT_PATH/../../parts/shared/require_twig_components.sh -e"CE" -b"b-7.0.x"
$SCRIPT_PATH/../../parts/shared/require_theme_dev.sh -t"twig" -b"b-7.0.x"

# Configure modules in composer
git clone https://github.com/OXID-eSales/module-template.git --branch=b-7.0.x source/dev-packages/moduletemplate
docker-compose exec -T \
  php composer config repositories.oxid-esales/module-template \
  --json '{"type":"path", "url":"./dev-packages/moduletemplate", "options": {"symlink": true}}'
docker-compose exec -T php composer require oxid-esales/module-template:* --no-update

docker-compose exec -T \
  php composer config repositories.oxid-esales/oxideshop-demodata-ce \
  --json '{"type":"git", "url":"https://github.com/OXID-eSales/oxideshop_demodata_ce"}'
docker-compose exec -T php composer require oxid-esales/oxideshop-demodata-ce:dev-b-7.0.x --no-update

# Install all preconfigured dependencies
docker-compose exec -T php composer update --no-interaction

$SCRIPT_PATH/../../parts/shared/setup_database.sh

docker-compose exec -T php bin/oe-console oe:module:activate oe_moduletemplate
docker-compose exec -T php bin/oe-console oe:theme:activate twig

$SCRIPT_PATH/../../parts/shared/create_admin.sh

echo "Done!"
