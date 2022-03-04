#!/bin/bash

SCRIPT_PATH=$(dirname ${BASH_SOURCE[0]})

cd $SCRIPT_PATH/../../../../ || exit

git clone https://github.com/OXID-eSales/oxideshop_ce.git --branch=b-6.4.x source

# Prepare services configuration
make setup
make addbasicservices

# Configure containers
perl -pi\
  -e 'print "xdebug.max_nesting_level=1000\n" if $. == 1'\
  containers/php/custom.ini

perl -pi\
  -e 's#/var/www/#/var/www/source/#g;'\
  containers/httpd/project.conf

# Configure shop
cp source/source/config.inc.php.dist source/source/config.inc.php

perl -pi\
  -e 'print "SetEnvIf Authorization \"(.*)\" HTTP_AUTHORIZATION=\$1\n\n" if $. == 1'\
  source/source/.htaccess

perl -pi\
  -e 's#<dbHost>#mysql#g;'\
  -e 's#<dbUser>#root#g;'\
  -e 's#<dbName>#example#g;'\
  -e 's#<dbPwd>#root#g;'\
  -e 's#<dbPort>#3306#g;'\
  -e 's#<sShopURL>#http://localhost.local/#g;'\
  -e 's#<sShopDir>#/var/www/source/#g;'\
  -e 's#<sCompileDir>#/var/www/source/tmp/#g;'\
  source/source/config.inc.php

# Clone GraphQL modules to modules directory
git clone https://github.com/OXID-eSales/graphql-base-module --branch=b-6.4.x source/source/modules/oe/graphql-base
git clone https://github.com/OXID-eSales/graphql-storefront-module --branch=b-6.4.x source/source/modules/oe/graphql-storefront

# Start all containers
make up

# Configure modules in composer
docker-compose exec -T \
  php composer config repositories.oxid-esales/grapqhl-base \
  --json '{"type":"path", "url":"./source/modules/oe/graphql-base", "options": {"symlink": true}}'

docker-compose exec -T \
  php composer config repositories.oxid-esales/grapqhl-storefront \
  --json '{"type":"path", "url":"./source/modules/oe/graphql-storefront", "options": {"symlink": true}}'

docker-compose exec -T php composer require oxid-esales/graphql-base:* --no-update
docker-compose exec -T php composer require oxid-esales/graphql-storefront:* --no-update

# Configure Tests dependencies
docker-compose exec -T php composer require codeception/module-rest ^1.4.2 --dev --no-update
docker-compose exec -T php composer require codeception/module-phpbrowser ^1.0.2 --dev --no-update

# Run dependencies installation and reset the shop to development state
docker-compose exec -T php composer update --no-interaction
docker-compose exec -T php php vendor/bin/reset-shop

# Install and activate modules
docker-compose exec -T php bin/oe-console oe:module:install-configuration source/modules/oe/graphql-base
docker-compose exec -T php bin/oe-console oe:module:install-configuration source/modules/oe/graphql-storefront
docker-compose exec -T php bin/oe-console oe:module:activate oe_graphql_base
docker-compose exec -T php bin/oe-console oe:module:activate oe_graphql_storefront
docker-compose exec -T php vendor/bin/oe-eshop-doctrine_migration migrations:migrate

echo "Done!"