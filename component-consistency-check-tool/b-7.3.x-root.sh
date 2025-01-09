#!/bin/bash
# Flags possible:
# -e for shop edition. Possible values: CE/EE

edition='CE'
while getopts e: flag; do
  case "${flag}" in
  e) edition=${OPTARG} ;;
  *) ;;
  esac
done

SCRIPT_PATH=$(dirname ${BASH_SOURCE[0]})

cd $SCRIPT_PATH/../../../ || exit

# Prepare services configuration
make setup
make addbasicservices
make file=services/adminer.yml addservice
make file=services/selenium-chrome.yml addservice

# Configure containers
perl -pi\
  -e 's#error_reporting = .*#error_reporting = E_ALL ^ E_DEPRECATED#g;'\
  containers/php/custom.ini

perl -pi\
  -e 's#/var/www/#/var/www/source/#g;'\
  containers/httpd/project.conf

perl -pi\
  -e 's#PHP_VERSION=.*#PHP_VERSION=8.2#g;'\
  .env

mkdir source
docker compose up --build -d php

git clone https://github.com/OXID-eSales/consistency-check-tool ./source -b b-7.3.x-create-skeleton-OXDEV-9049

$SCRIPT_PATH/../parts/shared/require_shop_edition_packages.sh -e"${edition}" -v"dev-b-7.3.x"

docker compose exec php composer update --no-interaction

make up

$SCRIPT_PATH/../parts/shared/setup_database.sh


$SCRIPT_PATH/../parts/shared/create_admin.sh