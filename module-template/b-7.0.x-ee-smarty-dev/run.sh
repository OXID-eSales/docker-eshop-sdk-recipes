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

# Configure modules in composer
git clone https://github.com/OXID-eSales/module-template.git --branch=b-7.0.x source/dev-packages/moduletemplate
docker compose exec -T \
  php composer config repositories.oxid-esales/module-template \
  --json '{"type":"path", "url":"./dev-packages/moduletemplate", "options": {"symlink": true}}'
docker compose exec -T php composer require oxid-esales/module-template:* --no-update

# Reconfigure the tests config to run smarty tests
perl -pi \
  -e 's#admin_twig#admin_smarty#g;' \
  -e 's#visualcms-module#visualcms-smarty-module#g;' \
  -e 's#views/apex#views/flow/translations#g;' \
  source/dev-packages/moduletemplate/tests/Codeception/acceptance.suite.yml

docker compose exec -T \
  php composer config repositories.oxid-esales/oxideshop-demodata-ee \
  --json '{"type":"git", "url":"https://github.com/OXID-eSales/oxideshop_demodata_ee"}'
docker compose exec -T php composer require oxid-esales/oxideshop-demodata-ee:dev-b-7.0.x-SMARTY --no-update

# Install all preconfigured dependencies
docker compose exec -T php composer update --no-interaction

$SCRIPT_PATH/../../parts/shared/setup_database.sh

docker compose exec -T php bin/oe-console oe:module:activate oe_moduletemplate

$SCRIPT_PATH/../../parts/shared/create_admin.sh

echo "Done!"