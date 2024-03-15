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

docker compose up --build -d php

AUTOLOAD_DEV='
      "psr-4": {
        "OxidEsales\\\\EshopCommunity\\\\Tests\\\\": "./vendor/oxid-esales/oxideshop-ce/tests"
      }'

cp ${SCRIPT_PATH}/../parts/shared/composer.json.base ./source/composer.json
perl -pi\
  -e "s#\"autoload-dev\": {#\"autoload-dev\":{${AUTOLOAD_DEV}#g;"\
  ./source/composer.json

## Escape it for use as a Sed replacement string.
## (https://stackoverflow.com/questions/29613304/is-it-possible-to-escape-regex-metacharacters-reliably-with-sed)
#IFS= read -d '' -r < <(sed -e ':a' -e '$!{N;ba' -e '}' -e 's/[&/\]/\\&/g; s/\n/\\&/g' <<<"$AUTOLOAD_DEV")
#AUTOLOAD_DEV_ESCAPED=${REPLY%$'\n'}
#
#sed -e "s/\<autoloadDev>/${AUTOLOAD_DEV_ESCAPED}/" ${SCRIPT_PATH}/../parts/shared/composer.json.base > ./source/composer.json

docker compose exec php composer config repositories.oxid-esales/oxideshop-ce git https://github.com/OXID-eSales/oxideshop_ce.git
docker compose exec php composer require oxid-esales/oxideshop-ce:dev-b-7.0.x --no-update
docker compose exec php composer require oxid-esales/developer-tools:dev-b-7.0.x --no-update

docker compose exec php composer require oxid-esales/graphql-configuration-access:dev-b-7.0.x-new_dev_recipes-OXDEV-7845

$SCRIPT_PATH/../parts/shared/require_theme.sh -t"apex" -b"b-7.0.x"
docker compose exec php composer update --no-interaction

make up

docker compose exec php vendor/bin/oe-console oe:setup:shop --db-host=mysql --db-port=3306 --db-name=example --db-user=root \
  --db-password=root --shop-url=http://localhost.local/ --shop-directory=/var/www/source/ \
  --compile-directory=/var/www/source/tmp/

docker compose exec -T php vendor/bin/oe-console oe:database:reset --db-host=mysql --db-port=3306 --db-name=example --db-user=root --db-password=root --force
