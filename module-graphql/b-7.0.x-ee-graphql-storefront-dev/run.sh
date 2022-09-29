#!/bin/bash

SCRIPT_PATH=$(dirname ${BASH_SOURCE[0]})

cd $SCRIPT_PATH/../../../../ || exit

git clone https://github.com/OXID-eSales/oxideshop_ce.git --branch=b-7.0.x source

# Prepare services configuration
make setup
make addbasicservices

# Configure containers
perl -pi\
  -e 's#error_reporting = .*#error_reporting = E_ALL ^ E_WARNING ^ E_DEPRECATED#g;'\
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
git clone https://github.com/OXID-eSales/graphql-base-module.git --branch=master source/source/modules/oe/graphql-base
git clone https://github.com/OXID-eSales/graphql-storefront-module.git --branch=master source/source/modules/oe/graphql-storefront

# Start all containers
make up

# Update composer to 2.4+
docker-compose exec php sudo composer self-update --2

docker-compose exec php composer config repositories.oxid-esales/oxideshop-pe git https://github.com/OXID-eSales/oxideshop_pe.git
docker-compose exec php composer config repositories.oxid-esales/oxideshop-ee git https://github.com/OXID-eSales/oxideshop_ee.git
docker-compose exec php composer require oxid-esales/oxideshop-pe:dev-b-7.0.x --no-update
docker-compose exec php composer require oxid-esales/oxideshop-ee:dev-b-7.0.x --no-plugins --no-scripts

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
docker-compose exec -T php bin/oe-console oe:database:reset --db-host=mysql --db-port=3306 --db-name=example --db-user=root --db-password=root --force
docker-compose exec -T php bin/oe-console oe:setup:demodata

# Install and activate modules
docker-compose exec -T php bin/oe-console oe:module:install vendor/oxid-esales/graphql-base
docker-compose exec -T php bin/oe-console oe:module:install vendor/oxid-esales/graphql-storefront
docker-compose exec -T php bin/oe-console oe:module:activate oe_graphql_base
docker-compose exec -T php bin/oe-console oe:module:activate oe_graphql_storefront

docker-compose exec -T php bin/oe-console oe:admin:create --admin-email='admin@admin.com' --admin-password='admin'

echo "Done! Admin login: admin@admin.com Password: admin"