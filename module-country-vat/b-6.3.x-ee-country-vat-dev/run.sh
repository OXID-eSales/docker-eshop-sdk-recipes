#!/bin/bash

SCRIPT_PATH=$(dirname ${BASH_SOURCE[0]})

cd $SCRIPT_PATH/../../../../ || exit

git clone https://github.com/OXID-eSales/oxideshop_ce.git --branch=b-6.3.x source

# Prepare services configuration
make setup
make addbasicservices

# Configure containers
perl -pi\
  -e 's#/var/www/#/var/www/source/#g;'\
  containers/httpd/project.conf

perl -pi\
  -e 's#PHP_VERSION=.*#PHP_VERSION="7.4"#g;'\
  .env

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

# Clone Country VAT module to modules directory
git clone git@github.com:OXID-eSales/country-vat-module.git --branch=b-6.x source/source/modules/oxps/countryvatadministration

# Start all containers
make up

docker-compose exec php composer config repositories.oxid-esales/oxideshop-ee git https://github.com/OXID-eSales/oxideshop_ee
docker-compose exec php composer config repositories.oxid-esales/oxideshop-pe git https://github.com/OXID-eSales/oxideshop_pe
docker-compose exec php composer require oxid-esales/oxideshop-pe:dev-b-6.3.x --no-update
docker-compose exec php composer require oxid-esales/oxideshop-ee:dev-b-6.3.x --no-update

# Configure modules in composer
docker-compose exec -T \
  php composer config repositories.oxid-professional-services/countryvatadministration \
  --json '{"type":"path", "url":"./source/modules/oxps/countryvatadministration", "options": {"symlink": true}}'
docker-compose exec -T php composer require oxid-professional-services/countryvatadministration:* --no-update

docker-compose exec -T php composer update --no-interaction
docker-compose exec -T php php vendor/bin/reset-shop

docker-compose exec -T php bin/oe-console oe:module:install-configuration source/modules/oxps/countryvatadministration/
docker-compose exec -T php bin/oe-console oe:module:activate oxps/countryvatadministration

echo "Done!"