#!/bin/bash

SCRIPT_PATH=$(dirname ${BASH_SOURCE[0]})

cd $SCRIPT_PATH/../../../../ || exit

git clone https://github.com/OXID-eSales/oxideshop_ce.git --branch=b-6.5.x source

make setup
make addbasicservices
make file=services/adminer.yml addservice
make file=services/selenium-chrome.yml addservice
make file=recipes/oxid-esales/services/selenium-firefox-old.yml addservice

# Configure containers
perl -pi\
  -e 's#/var/www/#/var/www/source/#g;'\
  containers/httpd/project.conf

# 6.5 stores encrypted config values with the MySQL ENCODE()/DECODE() functions,
# which MySQL removed in 8.0. With the SDK default (8.4) the shop installer dies
# with "FUNCTION example.DECODE does not exist".
perl -pi\
  -e 's#MYSQL_VERSION=.*#MYSQL_VERSION=5.7#g;'\
  .env

# Configure shop
cp source/source/config.inc.php.dist source/source/config.inc.php

perl -pi\
  -e 'print "SetEnvIf Authorization \"(.*)\" HTTP_AUTHORIZATION=\$1\n\n" if $. == 1'\
  source/source/.htaccess

perl -pi\
  -e 's#<dbHost>#mysql#g;'\
  -e 's#<dbUser>#root#g;'\
  -e 's#<dbName>#example#g;'\
  -e 's#<dbPwd>#root#g;'\
  -e 's#<dbPort>#3306#g;'\
  -e 's#<sShopURL>#http://localhost.local/#g;'\
  -e 's#<sShopDir>#/var/www/source/#g;'\
  -e 's#<sCompileDir>#/var/www/source/tmp/#g;'\
  source/source/config.inc.php

# Start all containers
make up

docker compose exec php composer config github-protocols https

# Composer 2.9+ blocks smarty/smarty 2.6, which is EOL and permanently flagged
docker compose exec -T php composer config policy.advisories.ignore '{"smarty/smarty": "6.5 is pinned to the EOL 2.6 line, which will never get a fixed release"}' --json

docker compose exec -T php composer update --no-interaction
docker compose exec -T php php vendor/bin/reset-shop

echo "Done!"
