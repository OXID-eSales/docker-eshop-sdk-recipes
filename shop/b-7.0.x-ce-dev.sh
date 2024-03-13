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
cp $SCRIPT_PATH/../parts/shared/composer.json.base ../../../source/composer.json

docker compose up --build -d php

docker compose exec php composer init --no-interaction --name="oxid-esales/oxideshop-project" --stability=dev

docker compose exec php composer config github-protocols https
docker compose exec php composer config allow-plugins.oxid-esales/oxideshop-composer-plugin true
docker compose exec php composer config allow-plugins.oxid-esales/oxideshop-unified-namespace-generator true
docker compose exec php composer config preferred-install.oxid-esales/* source


# Define sample multi-line literal.
replace='Laurel & Hardy; PS\2
Masters\1 & Johnson\2'

AUTOLOAD_DEV='"autoload-dev": {
      "psr-4": {
        "OxidEsales\\EshopCommunity\\Tests\\": "./vendor/oxid-esales/oxideshop-ce/tests"
      }
    },'

# Escape it for use as a Sed replacement string.
# (https://stackoverflow.com/questions/29613304/is-it-possible-to-escape-regex-metacharacters-reliably-with-sed)
IFS= read -d '' -r < <(sed -e ':a' -e '$!{N;ba' -e '}' -e 's/[&/\]/\\&/g; s/\n/\\&/g' <<<"$AUTOLOAD_DEV")
AUTOLOAD_DEV_ESCAPED=${REPLY%$'\n'}

sed -e "s/\<autoloadDev>/${AUTOLOAD_DEV_ESCAPED}/" ${SCRIPT_PATH}/parts/shared/composer.json.base > $SCRIPT_PATH/../../source/composer.json

docker compose exec php composer config repositories.oxid-esales/oxideshop-ce git https://github.com/OXID-eSales/oxideshop_ce.git
docker compose exec php composer require oxid-esales/oxideshop-ce:dev-b-7.0.x --no-update
$SCRIPT_PATH/../parts/shared/require_theme.sh -t"twig" -b"b-7.0.x"
docker compose exec php composer update --no-interaction

make up
