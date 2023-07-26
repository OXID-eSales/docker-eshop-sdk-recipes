#!/bin/bash

SCRIPT_PATH=$(dirname ${BASH_SOURCE[0]})

cd $SCRIPT_PATH/../../../../ || exit

# Prepare services configuration
make setup
make addbasicservices
make file=services/adminer.yml addservice

$SCRIPT_PATH/../../parts/b-7.0.x/start_shop.sh -eEE
$SCRIPT_PATH/../../parts/shared/require_twig_components.sh -e"EE" -b"b-7.0.x"
$SCRIPT_PATH/../../parts/shared/require_theme_dev.sh -t"apex" -b"b-7.0.x"

# Clone GraphQL modules to modules directory
git clone https://github.com/OXID-eSales/graphql-base-module.git --branch=b-7.0.x source/dev-packages/graphql-base
git clone https://github.com/OXID-eSales/graphql-storefront-module.git --branch=b-7.0.x source/dev-packages/graphql-storefront

# Add Sphinx container
make docpath=./source/dev-packages/graphql-base/docs addsphinxservice
make up

# Configure modules in composer
docker-compose exec -T \
  php composer config repositories.oxid-esales/grapqhl-base \
  --json '{"type":"path", "url":"./dev-packages/graphql-base", "options": {"symlink": true}}'

docker-compose exec -T \
  php composer config repositories.oxid-esales/grapqhl-storefront \
  --json '{"type":"path", "url":"./dev-packages/graphql-storefront", "options": {"symlink": true}}'

docker-compose exec -T \
  php composer config repositories.oxid-esales/oxideshop-demodata-ee \
  --json '{"type":"git", "url":"https://github.com/OXID-eSales/oxideshop_demodata_ee"}'

docker-compose exec -T php composer require oxid-esales/graphql-base:* --no-update
docker-compose exec -T php composer require oxid-esales/graphql-storefront:* --no-update
docker-compose exec -T php composer require oxid-esales/oxideshop-demodata-ee:dev-b-7.0.x --no-update

# Configure Tests dependencies
docker-compose exec -T php composer require codeception/module-rest ^3.3.0 --dev --no-update
docker-compose exec -T php composer require codeception/module-phpbrowser ^3.0.0 --dev --no-update

# Run dependencies installation and reset the shop to development state
docker-compose exec -T php composer update --no-interaction

$SCRIPT_PATH/../../parts/shared/setup_database.sh

# Install and activate modules
docker-compose exec -T php bin/oe-console oe:module:install vendor/oxid-esales/graphql-base
docker-compose exec -T php bin/oe-console oe:module:install vendor/oxid-esales/graphql-storefront
docker-compose exec -T php bin/oe-console oe:module:activate oe_graphql_base
docker-compose exec -T php bin/oe-console oe:module:activate oe_graphql_storefront
docker-compose exec -T php bin/oe-console oe:theme:activate twig

$SCRIPT_PATH/../../parts/shared/create_admin.sh

echo "Done!"