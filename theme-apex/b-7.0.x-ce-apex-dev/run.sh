#!/bin/bash

SCRIPT_PATH=$(dirname ${BASH_SOURCE[0]})

cd $SCRIPT_PATH/../../../../ || exit

git clone https://github.com/OXID-eSales/oxideshop_ce.git --branch=b-7.0.x source

# Prepare services configuration
make setup
make addbasicservices
make file=services/selenium-chrome.yml addservice
make file=recipes/oxid-esales/services/selenium-firefox-old.yml addservice

#change php version to 8.1
perl -pi\
  -e 's#PHP_VERSION=.*#PHP_VERSION="8.1"#g;'\
  .env

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

# Clone apex theme to themes directory
git clone git@github.com:OXID-eSales/apex-theme.git --branch=main source/source/Application/views/apex

# Start all containers
make up

# Configure modules in composer
docker-compose exec -T \
  php composer config repositories.oxid-esales/apex-theme \
  --json '{"type":"path", "url":"./source/Application/views/apex", "options": {"symlink": true}}'

# Add twig-component and themes
docker-compose exec -T php composer require oxid-esales/twig-component:dev-b-7.0.x --no-update
docker-compose exec -T php composer require oxid-esales/twig-admin-theme:dev-b-7.0.x --no-update
docker-compose exec -T php composer require oxid-esales/apex-theme:* --no-update

# Run dependencies installation and reset the shop to development state
docker-compose exec -T php composer update --no-interaction
docker-compose exec -T php php vendor/bin/reset-shop

#Symlink /out/apex
cd source/source/Application/views

ln -s ../Application/views/apex/out/apex/ ../../out/apex

docker-compose exec -T php bin/oe-console oe:admin:create --admin-email='admin@admin.com' --admin-password='admin'

echo "Done!"
echo "Admin login: admin@admin.com Password: admin"
echo "Activate APEX theme in admin"
