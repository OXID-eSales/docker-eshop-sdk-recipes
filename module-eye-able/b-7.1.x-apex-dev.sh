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

$SCRIPT_PATH/../parts/b-7.1.x/start_shop.sh -e"${edition}"
$SCRIPT_PATH/../parts/shared/require_twig_components.sh -e"${edition}" -b"b-7.1.x"
$SCRIPT_PATH/../parts/shared/require_theme_dev.sh -t"apex" -b"b-7.1.x"

$SCRIPT_PATH/../parts/shared/require_demodata_package.sh -e"${edition}" -b"b-7.1.x"

make up

# Clone GDPR opt-in module to modules directory
git clone https://github.com/Tobias-Eye-Able/eye-able-oxid-module.git --branch=b-7.1.x source/dev-packages/eyeable

# Configure module in composer
docker compose exec -T \
  php composer config repositories.eyeable/eye-able-oxid \
  --json '{"type":"path", "url":"./dev-packages/eyeable", "options": {"symlink": true}}'
docker compose exec -T php composer require eyeable/eye-able-oxid:* --no-update

# Install all preconfigured dependencies
docker compose exec -T php composer update --no-interaction

$SCRIPT_PATH/../parts/shared/setup_database.sh

docker compose exec -T php bin/oe-console oe:module:activate eyeable_assist
docker compose exec -T php bin/oe-console oe:theme:activate apex

$SCRIPT_PATH/../parts/shared/create_admin.sh

echo "Done!"