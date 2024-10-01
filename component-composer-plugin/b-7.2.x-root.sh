#!/bin/bash

SCRIPT_PATH=$(dirname ${BASH_SOURCE[0]})

cd $SCRIPT_PATH/../../../ || exit

# Prepare services configuration
make setup
make addbasicservices

# Configure containers
perl -pi\
  -e 's#error_reporting = .*#error_reporting = E_ALL ^ E_WARNING ^ E_DEPRECATED#g;'\
  containers/php/custom.ini

#perl -pi\
#  -e 's#/var/www/#/var/www/source/#g;'\
#  containers/httpd/project.conf
#
perl -pi\
  -e 's#PHP_VERSION=.*#PHP_VERSION=8.2#g;'\
  .env

mkdir source
docker compose up --build -d php

git clone https://github.com/OXID-eSales/oxideshop_composer_plugin ./source -b b-7.2.x

docker compose exec php composer update --no-interaction

make up