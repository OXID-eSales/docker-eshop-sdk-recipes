#!/bin/bash

SCRIPT_PATH=$(dirname ${BASH_SOURCE[0]})

cd $SCRIPT_PATH/../../../../ || exit

# Prepare services configuration
make setup
make addbasicservices
make file=services/adminer.yml addservice

$SCRIPT_PATH/../../parts/b-7.0.x/start_shop.sh -eEE
$SCRIPT_PATH/../../parts/shared/require_twig_components.sh -e"EE" -b"b-7.0.x"
$SCRIPT_PATH/../../parts/shared/require_theme.sh -t"twig" -b"b-7.0.x"

# Require demodata package
docker compose exec -T \
  php composer config repositories.oxid-esales/oxideshop-demodata-ee \
  --json '{"type":"git", "url":"https://github.com/OXID-eSales/oxideshop_demodata_ee"}'
docker compose exec -T php composer require oxid-esales/oxideshop-demodata-ee:dev-b-7.0.x --no-update

# Clone GDPR opt-in module to modules directory
git clone https://github.com/OXID-eSales/gdpr-optin-module.git --branch=b-7.0.x source/dev-packages/gdproptin

# Configure module in composer
docker compose exec -T \
  php composer config repositories.oxid-esales/gdpr-optin-module \
  --json '{"type":"path", "url":"./dev-packages/gdproptin", "options": {"symlink": true}}'
docker compose exec -T php composer require oxid-esales/gdpr-optin-module:* --no-update

# Install all preconfigured dependencies
docker compose exec -T php composer update --no-interaction

# ensure database, add demodata
$SCRIPT_PATH/../../parts/shared/setup_database.sh

# activate module, create admin
docker compose exec -T php bin/oe-console oe:module:reset-configurations --shop-id=1
docker compose exec -T php bin/oe-console oe:module:install-assets
docker compose exec -T php bin/oe-console oe:module:install source/modules/oe/gdproptin --shop-id=1
docker compose exec -T php bin/oe-console oe:module:activate oegdproptin
docker compose exec -T php bin/oe-console oe:theme:activate twig

$SCRIPT_PATH/../../parts/shared/create_admin.sh

echo "Done!"
