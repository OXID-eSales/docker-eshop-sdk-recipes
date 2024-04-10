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

AUTOLOAD_DEV='
      "psr-4": {
        "OxidEsales\\\\EshopCommunity\\\\Tests\\\\": "./vendor/oxid-esales/oxideshop-ce/tests"
      }'

cp ${SCRIPT_PATH}/../parts/bases/composer.json.base ./source/composer.json
perl -pi\
  -e "s#\"autoload-dev\": {#\"autoload-dev\":{${AUTOLOAD_DEV}#g;"\
  ./source/composer.json

docker compose exec php composer config repositories.oxid-esales/oxideshop-ce git https://github.com/OXID-eSales/oxideshop_ce.git
docker compose exec php composer require oxid-esales/oxideshop-ce:dev-b-7.1.x --no-update
docker compose exec php composer require oxid-esales/developer-tools:dev-b-7.1.x --no-update

docker compose exec php composer require oxid-esales/module-template:dev-b-7.1.x_compilation_installation

$SCRIPT_PATH/../parts/shared/require_theme.sh -t"twig-admin" -b"b-7.1.x"
$SCRIPT_PATH/../parts/shared/require_theme.sh -t"apex" -b"b-7.1.x"
docker compose exec php composer update --no-interaction

make up

$SCRIPT_PATH/../parts/shared/require_demodata_package.sh -e"ce" -b"b-7.1.x"

docker compose exec php vendor/bin/oe-console oe:setup:shop --db-host=mysql --db-port=3306 --db-name=example --db-user=root \
  --db-password=root --shop-url=http://localhost.local/ --shop-directory=/var/www/source/ \
  --compile-directory=/var/www/source/tmp/

docker compose exec -T php vendor/bin/oe-console oe:database:reset --db-host=mysql --db-port=3306 --db-name=example --db-user=root --db-password=root --force

docker compose exec -T php vendor/bin/oe-console oe:module:activate oe_moduletemplate
docker compose exec -T php vendor/bin/oe-console oe:theme:activate apex

docker compose exec -T php vendor/bin/oe-console oe:admin:create --admin-email="noreply@oxid-esales.com" --admin-password="admin"
echo -e "\033[1;37m\033[1;42mCreate admin: Admin login: noreply@oxid-esales.com Password: admin\033[0m\n"

# Register all related project packages git repositories
cp ${SCRIPT_PATH}/../parts/bases/vcs.xml.base .idea/vcs.xml
perl -pi\
  -e 's#</component>#<mapping directory="\$PROJECT_DIR\$/source/vendor/oxid-esales/oxideshop-ce" vcs="Git" />\n  </component>#g;'\
  -e 's#</component>#<mapping directory="\$PROJECT_DIR\$/source/vendor/oxid-esales/module-template" vcs="Git" />\n  </component>#g;'\
  .idea/vcs.xml
