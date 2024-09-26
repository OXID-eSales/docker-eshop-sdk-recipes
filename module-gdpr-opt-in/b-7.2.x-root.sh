#!/bin/bash
# Flags possible:
# -e for shop edition. Possible values: CE/EE

edition='EE'
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
make file=services/selenium-chrome.yml addservice

# Configure containers
perl -pi\
  -e 's#error_reporting = .*#error_reporting = E_ALL ^ E_WARNING ^ E_DEPRECATED#g;'\
  containers/php/custom.ini

perl -pi\
  -e 's#/var/www/#/var/www/source/#g;'\
  containers/httpd/project.conf

perl -pi\
  -e 's#PHP_VERSION=.*#PHP_VERSION=8.2#g;'\
  .env

mkdir source
docker compose up --build -d php

git clone https://github.com/OXID-eSales/gdpr-optin-module ./source -b b-7.2.x-root-experiment

$SCRIPT_PATH/../parts/shared/require_shop_edition_packages.sh -e"${edition}" -v"dev-b-7.2.x"
$SCRIPT_PATH/../parts/shared/require_twig_components.sh -e"${edition}" -b"b-7.2.x"
$SCRIPT_PATH/../parts/shared/require_theme_dev.sh -t"apex" -b"b-7.2.x"
$SCRIPT_PATH/../parts/shared/require_demodata_package.sh -e"${edition}" -b"b-7.2.x"

docker compose exec php composer update --no-interaction

make up

$SCRIPT_PATH/../parts/shared/setup_database.sh

docker compose exec -T php vendor/bin/oe-console oe:module:install ./

docker compose exec -T php vendor/bin/oe-console oe:module:activate oegdproptin
docker compose exec -T php vendor/bin/oe-console oe:theme:activate apex

$SCRIPT_PATH/../parts/shared/create_admin.sh