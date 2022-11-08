#!/bin/bash

SCRIPT_PATH=$(dirname ${BASH_SOURCE[0]})

cd $SCRIPT_PATH/../../../../ || exit

# Prepare services configuration
make setup
make addbasicservices

$SCRIPT_PATH/../../parts/b-7.0.x/start_shop.sh -eEE
$SCRIPT_PATH/../../parts/b-7.0.x/require_twig_components.sh -eEE

# Clone GraphQL modules to modules directory
git clone https://github.com/OXID-eSales/graphql-base-module.git --branch=b-7.0.x source/source/modules/oe/graphql-base
git clone https://github.com/OXID-eSales/graphql-storefront-module.git --branch=b-7.0.x source/source/modules/oe/graphql-storefront

# Configure modules in composer
docker-compose exec -T \
  php composer config repositories.oxid-esales/grapqhl-base \
  --json '{"type":"path", "url":"./source/modules/oe/graphql-base", "options": {"symlink": true}}'

docker-compose exec -T \
  php composer config repositories.oxid-esales/grapqhl-storefront \
  --json '{"type":"path", "url":"./source/modules/oe/graphql-storefront", "options": {"symlink": true}}'

docker-compose exec -T \
  php composer config repositories.oxid-esales/oxideshop-demodata-ee \
  --json '{"type":"git", "url":"https://github.com/OXID-eSales/oxideshop_demodata_ee"}'

docker-compose exec -T php composer require oxid-esales/graphql-base:* --no-update
docker-compose exec -T php composer require oxid-esales/graphql-storefront:* --no-update
docker-compose exec -T php composer require oxid-esales/oxideshop-demodata-ee:dev-master --no-update

# Configure Tests dependencies
docker-compose exec -T php composer require codeception/module-rest ^3.3.0 --dev --no-update
docker-compose exec -T php composer require codeception/module-phpbrowser ^3.0.0 --dev --no-update

# Run dependencies installation and reset the shop to development state
docker-compose exec -T php composer update --no-interaction

$SCRIPT_PATH/../../parts/b-7.0.x/reset_database.sh -eEE

docker-compose exec -T php bin/oe-console oe:setup:demodata

# Install and activate modules
docker-compose exec -T php bin/oe-console oe:module:install vendor/oxid-esales/graphql-base
docker-compose exec -T php bin/oe-console oe:module:install vendor/oxid-esales/graphql-storefront
docker-compose exec -T php bin/oe-console oe:module:activate oe_graphql_base
docker-compose exec -T php bin/oe-console oe:module:activate oe_graphql_storefront

docker-compose exec -T php bin/oe-console oe:admin:create --admin-email='admin@admin.com' --admin-password='admin'

echo "Done! Admin login: admin@admin.com Password: admin"