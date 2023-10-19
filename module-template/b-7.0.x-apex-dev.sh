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

$SCRIPT_PATH/../parts/b-7.0.x/start_shop.sh -e"${edition}"
$SCRIPT_PATH/../parts/shared/require_twig_components.sh -e"${edition}" -b"b-7.0.x"
$SCRIPT_PATH/../parts/shared/require_theme_dev.sh -t"apex" -b"b-7.0.x"

$SCRIPT_PATH/../parts/shared/require_demodata_package.sh -e"${edition}" -b"b-7.0.x"

make up

# Configure modules in composer
git clone https://github.com/OXID-eSales/module-template.git --branch=b-7.0.x source/dev-packages/moduletemplate
docker compose exec -T \
  php composer config repositories.oxid-esales/module-template \
  --json '{"type":"path", "url":"./dev-packages/moduletemplate", "options": {"symlink": true}}'
docker compose exec -T php composer require oxid-esales/module-template:* --no-update

# Install all preconfigured dependencies
docker compose exec -T php composer update --no-interaction

$SCRIPT_PATH/../parts/shared/setup_database.sh

docker compose exec -T php bin/oe-console oe:module:activate oe_moduletemplate
docker compose exec -T php bin/oe-console oe:theme:activate apex

$SCRIPT_PATH/../parts/shared/create_admin.sh

echo "Done!"