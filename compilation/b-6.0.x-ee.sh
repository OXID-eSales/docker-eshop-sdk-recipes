#!/bin/bash

SCRIPT_PATH=$(dirname ${BASH_SOURCE[0]})

cd $SCRIPT_PATH/../../../ || exit


# Replace PHP version
perl -pi\
  -e 's#PHP_VERSION=7.4#PHP_VERSION=7.0#g;'\
  .env.dist

# Prepare services configuration
make setup
make addbasicservices
make file=services/adminer.yml addservice
make file=services/selenium-chrome.yml addservice
make file=recipes/oxid-esales/services/selenium-firefox-old.yml addservice

# Configure containers
perl -pi\
  -e 's#error_reporting = .*#error_reporting = E_ALL ^ E_WARNING ^ E_DEPRECATED#g;'\
  containers/php/custom.ini

perl -pi\
  -e 's#/var/www/#/var/www/source/#g;'\
  containers/httpd/project.conf

mkdir source

docker-compose up --build -d php
make up

docker-compose exec -T php php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
docker-compose exec -T php php -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'.PHP_EOL; } else { echo 'Installer corrupt'.PHP_EOL; unlink('composer-setup.php'); exit(1); }"
docker-compose exec -T php php composer-setup.php
docker-compose exec -T php php -r "unlink('composer-setup.php');"
docker-compose exec -T php sudo mv composer.phar /usr/bin/composer
docker-compose exec -T php sudo composer self-update --1

docker-compose exec -T php composer create-project oxid-esales/oxideshop-project . dev-b-6.0-ee

docker-compose exec -T php composer update --no-scripts --no-plugins
docker-compose exec -T php composer update


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

docker-compose exec -T php vendor/bin/reset-shop

docker-compose up --build -d apache

echo "Done"