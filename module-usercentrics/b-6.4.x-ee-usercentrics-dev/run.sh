#!/bin/bash

SCRIPT_PATH=$(dirname ${BASH_SOURCE[0]})

cd $SCRIPT_PATH/../../../../ || exit

git clone https://github.com/OXID-eSales/oxideshop_ce.git --branch=b-6.4.x source

# Prepare services configuration
make setup
make addbasicservices

# Configure containers
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

# Clone Usercentrics module to modules directory
git clone https://github.com/OXID-eSales/usercentrics.git --branch=b-6.3.x source/source/modules/oxps/usercentrics

# Start all containers
make up

docker-compose exec php composer config github-protocols https
docker-compose exec php composer config repositories.oxid-esales/oxideshop-pe git https://github.com/OXID-eSales/oxideshop_pe.git
docker-compose exec php composer config repositories.oxid-esales/oxideshop-ee git https://github.com/OXID-eSales/oxideshop_ee.git
docker-compose exec php composer require oxid-esales/oxideshop-pe:dev-b-6.4.x --no-update
docker-compose exec php composer require oxid-esales/oxideshop-ee:dev-b-6.4.x --no-plugins --no-scripts

# Configure modules in composer
docker-compose exec -T \
  php composer config repositories.oxid-professional-services/usercentrics \
  --json '{"type":"path", "url":"./source/modules/oxps/usercentrics", "options": {"symlink": true}}'
docker-compose exec -T php composer require oxid-professional-services/usercentrics:* --no-update

docker-compose exec -T php composer update --no-interaction
docker-compose exec -T php php vendor/bin/reset-shop

docker-compose exec -T php bin/oe-console oe:module:install-configuration source/modules/oxps/usercentrics/
docker-compose exec -T php bin/oe-console oe:module:activate oxps_usercentrics

echo "Done!"