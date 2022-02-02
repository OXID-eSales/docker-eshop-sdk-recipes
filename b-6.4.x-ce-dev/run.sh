#!/bin/bash

SCRIPT_PATH=$(dirname ${BASH_SOURCE[0]})

cd $SCRIPT_PATH/../../../ || exit

git clone https://github.com/OXID-eSales/oxideshop_ce.git --branch=b-6.4.x source

make setup
make file=services/selenium-chrome.yml addservice
make file=recipes/oxid-esales/services/selenium-firefox-old.yml addservice

sed -i '' -e "s/display_errors =.*/display_errors = false/"  containers/php-fpm/custom.ini
sed -i '' -e "s+/var/www/+/var/www/source/+" containers/httpd/project.conf

cp source/source/config.inc.php.dist source/source/config.inc.php
sed -i '' -e "1s+^+SetEnvIf Authorization "\(.*\)" HTTP_AUTHORIZATION=\$1\n\n+" source/source/.htaccess
sed -i '' -e 's/<dbHost>/mysql/'\
       -e 's/<dbUser>/root/'\
       -e 's/<dbName>/example/'\
       -e 's/<dbPwd>/root/'\
       -e 's/<dbPort>/3306/'\
       -e 's/<sShopURL>/http:\/\/localhost.local\//'\
       -e 's/<sShopDir>/\/var\/www\/source\//'\
       -e 's/<sCompileDir>/\/var\/www\/source\/tmp\//'\
    source/source/config.inc.php

make up

docker-compose exec -T php composer update --no-interaction
docker-compose exec -T php php vendor/bin/reset-shop

echo "Done!"