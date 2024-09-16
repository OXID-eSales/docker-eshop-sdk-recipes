#!/bin/bash

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
make file=services/adminer.yml addservice
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

$SCRIPT_PATH/../parts/shared/require_compilation.sh -e "ee" -m "b-7.2" -b "b-7.2.x"
$SCRIPT_PATH/../parts/shared/require_shop_edition_packages.sh -e"${edition}" -v"dev-b-7.2.x"
$SCRIPT_PATH/../parts/shared/require_twig_components.sh -e"${edition}" -b"b-7.2.x"
$SCRIPT_PATH/../parts/shared/require.sh -n"oxid-esales/apex-theme" -v"dev-b-7.2.x"
$SCRIPT_PATH/../parts/shared/require_demodata_package.sh -e"EE" -b"b-7.2.x"

#register repositories
$SCRIPT_PATH/../parts/shared/require.sh -n"oxid-esales/media-library-module" -g"https://github.com/OXID-eSales/media-library-module.git" -v"dev-b-7.2.x"
$SCRIPT_PATH/../parts/shared/require.sh -n"ddoe/wysiwyg-editor-module" -g"https://github.com/OXID-eSales/ddoe-wysiwyg-editor-module.git" -v"dev-b-7.2.x"
$SCRIPT_PATH/../parts/shared/require.sh -n"ddoe/visualcms-module" -g"https://github.com/OXID-eSales/visual_cms_module.git" -v"dev-b-7.2.x"

$SCRIPT_PATH/../parts/shared/require.sh -n"oxid-esales/gdpr-optin-module" -v"dev-b-7.2.x"
$SCRIPT_PATH/../parts/shared/require.sh -n"oxid-professional-services/usercentrics" -v"dev-b-7.2.x"
$SCRIPT_PATH/../parts/shared/require.sh -n"makaira/oxid-connect-essential" -v"v2.1.2"
$SCRIPT_PATH/../parts/shared/require.sh -n"eyeable/eye-able-oxid" -v"v3.0.3"

make up

docker compose exec php composer remove oxid-esales/oxideshop-metapackage-pe
docker compose exec php composer update  --no-interaction

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
