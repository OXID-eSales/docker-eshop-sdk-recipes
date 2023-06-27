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

# Clone Usercentrics module to modules directory and Configure modules in composer
git clone https://github.com/OXID-eSales/usercentrics.git --branch=b-7.0.x source/source/modules/oxps/usercentrics
docker-compose exec -T \
  php composer config repositories.oxid-professional-services/usercentrics \
  --json '{"type":"path", "url":"./source/modules/oxps/usercentrics", "options": {"symlink": true}}'
docker-compose exec -T php composer require oxid-professional-services/usercentrics:* --no-update

# Require demodata package
docker-compose exec -T \
  php composer config repositories.oxid-esales/oxideshop-demodata-ee \
  --json '{"type":"git", "url":"https://github.com/OXID-eSales/oxideshop_demodata_ee"}'
docker-compose exec -T php composer require oxid-esales/oxideshop-demodata-ee:dev-b-7.0.x-SMARTY --no-update

# Install all preconfigured dependencies
docker-compose exec -T php composer update --no-interaction

$SCRIPT_PATH/../../parts/b-7.0.x/reset_database.sh -eEE
docker-compose exec -T php bin/oe-console oe:admin:create --admin-email='admin@admin.com' --admin-password='admin'

docker-compose exec -T php bin/oe-console oe:module:activate oxps_usercentrics

echo "Done! Admin login: admin@admin.com Password: admin"
