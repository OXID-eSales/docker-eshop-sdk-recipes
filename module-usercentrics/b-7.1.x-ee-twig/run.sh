#!/bin/bash

SCRIPT_PATH=$(dirname ${BASH_SOURCE[0]})

cd $SCRIPT_PATH/../../../../ || exit

# Prepare services configuration
make setup
make addbasicservices
make file=services/adminer.yml addservice
make file=services/selenium-chrome.yml addservice

$SCRIPT_PATH/../../parts/b-7.1.x/start_shop.sh -eEE
$SCRIPT_PATH/../../parts/shared/require_twig_components.sh -e"EE" -b"b-7.1.x"
$SCRIPT_PATH/../../parts/shared/require_theme.sh -t"twig" -b"b-7.1.x"

# Clone Usercentrics module to modules directory and Configure modules in composer
git clone https://github.com/OXID-eSales/usercentrics.git --branch=b-7.1.x source/dev-packages/usercentrics
docker compose exec -T \
  php composer config repositories.oxid-professional-services/usercentrics \
  --json '{"type":"path", "url":"./dev-packages/usercentrics", "options": {"symlink": true}}'
docker compose exec -T php composer require oxid-professional-services/usercentrics:* --no-update

# Require demodata package
docker compose exec -T \
  php composer config repositories.oxid-esales/oxideshop-demodata-ee \
  --json '{"type":"git", "url":"https://github.com/OXID-eSales/oxideshop_demodata_ee"}'
docker compose exec -T php composer require oxid-esales/oxideshop-demodata-ee:dev-b-7.1.x --no-update

# Install all preconfigured dependencies
docker compose exec -T php composer update --no-interaction

$SCRIPT_PATH/../../parts/shared/setup_database.sh --no-demodata

docker compose exec -T php bin/oe-console oe:module:activate oxps_usercentrics
docker compose exec -T php bin/oe-console oe:theme:activate twig

$SCRIPT_PATH/../../parts/shared/create_admin.sh

echo "Done!"