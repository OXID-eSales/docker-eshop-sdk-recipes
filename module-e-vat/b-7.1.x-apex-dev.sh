#!/bin/bash

# Flags possible:
# -e for shop edition. Possible values: CE/PE/EE

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
make file=services/node.yml addservice

$SCRIPT_PATH/../parts/b-7.1.x/start_shop.sh -e"${edition}" -u"false"
$SCRIPT_PATH/../parts/shared/require_twig_components.sh -e"${edition}" -b"b-7.1.x"
$SCRIPT_PATH/../parts/shared/require_theme_dev.sh -t"apex" -b"b-7.1.x"

$SCRIPT_PATH/../parts/shared/require_demodata_package.sh -e"${edition}" -b"b-7.1.x"

# Configure eVat documentation
git clone https://github.com/OXID-eSales/vat-tbe-services-documentation.git --branch=2.1-en source/docs
make docpath=./source/docs addsphinxservice

make up

# Clone and configure module package in composer
git clone https://github.com/OXID-eSales/vat_tbe_services.git --branch=b-7.1.x source/dev-packages/oevattbe
docker compose exec -T \
  php composer config repositories.oxid-esales/evat-module \
  --json '{"type":"path", "url":"./dev-packages/oevattbe", "options": {"symlink": true}}'
docker compose exec -T php composer require oxid-esales/evat-module:* --no-update

# Install all preconfigured dependencies
docker compose exec -T php composer update --no-interaction

$SCRIPT_PATH/../parts/shared/setup_database.sh

docker compose exec -T php bin/oe-console oe:module:activate oevattbe
docker compose exec -T php bin/oe-console oe:theme:activate apex

$SCRIPT_PATH/../parts/shared/create_admin.sh

echo "Done!"