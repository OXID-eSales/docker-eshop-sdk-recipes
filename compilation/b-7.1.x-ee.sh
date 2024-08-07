#!/bin/bash

SCRIPT_PATH=$(dirname ${BASH_SOURCE[0]})

cd $SCRIPT_PATH/../../../ || exit

# Prepare services configuration
make setup
make addbasicservices
make file=services/adminer.yml addservice
make file=services/selenium-chrome.yml addservice

# Configure containers
perl -pi\
  -e 's#error_reporting = .*#error_reporting = E_ALL ^ E_WARNING ^ E_DEPRECATED#g;'\
  containers/php/custom.ini

perl -pi\
  -e 's#/var/www/#/var/www/source/#g;'\
  containers/httpd/project.conf

mkdir source

docker compose up --build -d php
docker compose run php composer create-project oxid-esales/oxideshop-project . dev-b-7.1-ee
make down

make up

docker compose exec -T php composer require oxid-esales/developer-tools:dev-b-7.1.x --no-update
docker compose exec -T php composer update

$SCRIPT_PATH/../parts/shared/setup_database.sh


docker compose exec -T php vendor/bin/oe-console oe:theme:activate apex

docker compose exec -T php vendor/bin/oe-console oe:module:activate oegdproptin
docker compose exec -T php vendor/bin/oe-console oe:module:activate makaira_oxid-connect-essential
docker compose exec -T php vendor/bin/oe-console oe:module:activate oxps_usercentrics
docker compose exec -T php vendor/bin/oe-console oe:module:activate ddoemedialibrary
docker compose exec -T php vendor/bin/oe-console oe:module:activate ddoewysiwyg
docker compose exec -T php vendor/bin/oe-console oe:module:activate ddoevisualcms

$SCRIPT_PATH/../parts/shared/create_admin.sh

echo "Done!"
