#!/bin/bash

SCRIPT_PATH=$(dirname ${BASH_SOURCE[0]})

cd $SCRIPT_PATH/../../../ || exit

# Prepare services configuration
make setup
make addbasicservices
make file=services/selenium-chrome.yml addservice

# Configure containers
perl -pi\
  -e 's#error_reporting = .*#error_reporting = E_ALL ^ E_WARNING ^ E_DEPRECATED#g;'\
  containers/php/custom.ini

perl -pi\
  -e 's#/var/www/#/var/www/source/#g;'\
  containers/httpd/project.conf

mkdir source

docker-compose up --build -d php
docker-compose run php composer create-project oxid-esales/oxideshop-project . dev-b-7.0-ee
make down

make up

docker-compose exec -T php vendor/bin/oe-console oe:setup:shop --db-host=mysql --db-port=3306 --db-name=example --db-user=root --db-password=root --shop-url=http://localhost.local --shop-directory=/var/www/source --compile-directory=/var/www/source/tmp
docker-compose exec -T php vendor/bin/oe-console oe:setup:demodata

docker-compose exec -T php vendor/bin/oe-console oe:admin:create --admin-email='admin@admin.com' --admin-password='admin'

#docker-compose exec -T php vendor/bin/oe-console oe:theme:activate twig

docker-compose exec -T php vendor/bin/oe-console oe:module:activate oegdproptin
docker-compose exec -T php vendor/bin/oe-console oe:module:activate makaira_oxid-connect-essential
docker-compose exec -T php vendor/bin/oe-console oe:module:activate oxps_usercentrics
docker-compose exec -T php vendor/bin/oe-console oe:module:activate ddoewysiwyg
docker-compose exec -T php vendor/bin/oe-console oe:module:activate ddoevisualcms

echo "Warning! Activate theme in the Admin!"
echo "Done! Admin login: admin@admin.com Password: admin"
