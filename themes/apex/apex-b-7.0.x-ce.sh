#!/bin/bash

SCRIPT_PATH=$(dirname ${BASH_SOURCE[0]})

cd $SCRIPT_PATH/../../../../ || exit

# Prepare services configuration
make setup
make addbasicservices

$SCRIPT_PATH/../../parts/b-7.0.x/start_shop.sh -eCE
$SCRIPT_PATH/../../parts/b-7.0.x/require_twig_components.sh -eCE

# Require demodata package
docker-compose exec -T \
  php composer config repositories.oxid-esales/oxideshop-demodata-ce \
  --json '{"type":"git", "url":"https://github.com/OXID-eSales/oxideshop_demodata_ce"}'
docker-compose exec -T php composer require oxid-esales/oxideshop-demodata-ce:dev-master --no-update

# Install all preconfigured dependencies
docker-compose exec -T php composer update --no-interaction

$SCRIPT_PATH/../../parts/b-7.0.x/reset_database.sh -eCE
docker-compose exec -T php bin/oe-console oe:setup:demodata
docker-compose exec -T php bin/oe-console oe:admin:create --admin-email='admin@admin.com' --admin-password='admin'
docker-compose exec -T php bin/oe-console oe:theme:activate apex

echo "Done! Admin login: admin@admin.com Password: admin"