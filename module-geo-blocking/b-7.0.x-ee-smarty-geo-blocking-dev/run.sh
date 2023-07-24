#!/bin/bash

SCRIPT_PATH=$(dirname ${BASH_SOURCE[0]})

cd $SCRIPT_PATH/../../../../ || exit

# Prepare services configuration
make setup
make addbasicservices
make file=services/adminer.yml addservice
make file=services/selenium-chrome.yml addservice

$SCRIPT_PATH/../../parts/b-7.0.x/start_shop.sh -eEE
$SCRIPT_PATH/../../parts/b-7.0.x/require_smarty_components.sh -eEE

# Require demodata package
docker-compose exec -T \
  php composer config repositories.oxid-esales/oxideshop-demodata-ee \
  --json '{"type":"git", "url":"https://github.com/OXID-eSales/oxideshop_demodata_ee"}'
docker-compose exec -T php composer require oxid-esales/oxideshop-demodata-ee:dev-b-7.0.x-SMARTY --no-update

# Clone GDPR opt-in module to modules directory
git clone git@github.com:OXID-eSales/geo-blocking-module.git --branch=b-7.0.x source/dev-packages/geoblocking

# Configure module in composer
docker-compose exec -T \
  php composer config repositories.oxid-esales/geo-blocking-module \
  --json '{"type":"path", "url":"./dev-packages/geoblocking", "options": {"symlink": true}}'
docker-compose exec -T php composer require oxid-esales/geo-blocking-module:* --no-update

# Install all preconfigured dependencies
docker-compose exec -T php composer update --no-interaction

# ensure database
$SCRIPT_PATH/../../parts/b-7.0.x/reset_database.sh -eEE

# add demodata, create admin, activate module
docker-compose exec -T php bin/oe-console oe:setup:demodata
docker-compose exec -T php bin/oe-console oe:module:reset-configurations --shop-id=1
docker-compose exec -T php bin/oe-console oe:module:install-assets
docker-compose exec -T php bin/oe-console oe:module:install source/modules/oe/geoblocking --shop-id=1
docker-compose exec -T php bin/oe-console oe:module:activate oegeoblocking

$SCRIPT_PATH/../../parts/shared/create_admin.sh

echo "Done!"
