#!/bin/bash

SCRIPT_PATH=$(dirname ${BASH_SOURCE[0]})

cd $SCRIPT_PATH/../../../../ || exit

# Prepare services configuration
make setup
make addbasicservices
make file=services/adminer.yml addservice

$SCRIPT_PATH/../../parts/b-7.0.x/start_shop.sh -eEE
$SCRIPT_PATH/../../parts/b-7.0.x/require_smarty_components.sh -eEE

# Require demodata package
docker-compose exec -T \
  php composer config repositories.oxid-esales/oxideshop-demodata-ee \
  --json '{"type":"git", "url":"https://github.com/OXID-eSales/oxideshop_demodata_ee"}'
docker-compose exec -T php composer require oxid-esales/oxideshop-demodata-ee:dev-master --no-update

# Clone Econda Analytics module to modules directory
git clone https://github.com/OXID-eSales/personalization-module.git --branch=master source/source/modules/oe/personalization

# Configure module in composer
docker-compose exec -T \
  php composer config repositories.oxid-esales/personalization-module \
  --json '{"type":"path", "url":"./source/modules/oe/personalization", "options": {"symlink": true}}'
docker-compose exec -T php composer require oxid-esales/personalization-module:* --no-update

# Install all preconfigured dependencies
docker-compose exec -T php composer update --no-interaction

# ensure database
$SCRIPT_PATH/../../parts/b-7.0.x/reset_database.sh -eEE

# add demodata, create admin, activate module
docker-compose exec -T php bin/oe-console oe:setup:demodata
docker-compose exec -T php bin/oe-console oe:admin:create --admin-email='admin@admin.com' --admin-password='admin'

docker-compose exec -T php bin/oe-console oe:module:activate oepersonalization

echo "Done! Admin login: admin@admin.com Password: admin"
