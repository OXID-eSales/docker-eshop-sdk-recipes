#!/bin/bash

SCRIPT_PATH=$(dirname ${BASH_SOURCE[0]})

cd $SCRIPT_PATH/../../../../ || exit

# Prepare services configuration
make setup
make addbasicservices

$SCRIPT_PATH/../../parts/b-7.0.x/start_shop.sh -eEE
$SCRIPT_PATH/../../parts/b-7.0.x/require_twig_components.sh -eEE

# Require demodata package
docker-compose exec -T \
  php composer config repositories.oxid-esales/oxideshop-demodata-ee \
  --json '{"type":"git", "url":"https://github.com/OXID-eSales/oxideshop_demodata_ee"}'
docker-compose exec -T php composer require oxid-esales/oxideshop-demodata-ee:dev-master --no-update

# Clone GDPR opt-in module to modules directory
git clone https://github.com/OXID-eSales/gdpr-optin-module.git --branch=b-7.0.x source/source/modules/oe/gdproptin

# Configure module in composer
docker-compose exec -T \
  php composer config repositories.oxid-esales/gdpr-optin-module \
  --json '{"type":"path", "url":"./source/modules/oe/gdproptin", "options": {"symlink": true}}'
docker-compose exec -T php composer require oxid-esales/gdpr-optin-module:* --no-update

# Install all preconfigured dependencies
docker-compose exec -T php composer update --no-interaction

# ensure database
$SCRIPT_PATH/../../parts/b-7.0.x/reset_database.sh -eEE

# add demodata, create admin, activate module
docker-compose exec -T php bin/oe-console oe:setup:demodata
docker-compose exec -T php bin/oe-console oe:admin:create --admin-email='admin@admin.com' --admin-password='admin'
docker-compose exec -T php bin/oe-console oe:module:reset-configurations --shop-id=1
docker-compose exec -T php bin/oe-console oe:module:install-assets
docker-compose exec -T php bin/oe-console oe:module:install source/modules/oe/gdproptin --shop-id=1
docker-compose exec -T php bin/oe-console oe:module:activate oegdproptin
docker-compose exec -T php bin/oe-console oe:theme:activate twig

echo "Done! Admin login: admin@admin.com Password: admin"
