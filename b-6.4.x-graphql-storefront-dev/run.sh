#!/bin/bash

SCRIPT_PATH=$(dirname ${BASH_SOURCE[0]})

cd $SCRIPT_PATH/../../../ || exit

git clone https://github.com/OXID-eSales/oxideshop_ce.git --branch=b-6.4.x source

make setup
sed "s/display_errors =.*/display_errors = false/" -i containers/php-fpm/custom.ini
sed -i -e "s+/var/www/+/var/www/source/+" containers/httpd/project.conf
sed -i "1s+^+xdebug.max_nesting_level=1000\n\n+" containers/php-fpm/custom.ini

cp source/source/config.inc.php.dist source/source/config.inc.php
sed -i "1s+^+SetEnvIf Authorization "\(.*\)" HTTP_AUTHORIZATION=\$1\n\n+" source/source/.htaccess
sed -i -e 's/<dbHost>/mysql/'\
       -e 's/<dbUser>/root/'\
       -e 's/<dbName>/example/'\
       -e 's/<dbPwd>/root/'\
       -e 's/<dbPort>/3306/'\
       -e 's/<sShopURL>/http:\/\/localhost.local\//'\
       -e 's/<sShopDir>/\/var\/www\/source\//'\
       -e 's/<sCompileDir>/\/var\/www\/source\/tmp\//'\
    source/source/config.inc.php

git clone https://github.com/OXID-eSales/graphql-base-module --branch=b-6.4.x source/source/modules/oe/graphql-base
git clone https://github.com/OXID-eSales/graphql-storefront-module --branch=b-6.4.x source/source/modules/oe/graphql-storefront

make up

docker-compose exec -T \
  php composer config repositories.oxid-esales/grapqhl-base \
  --json '{"type":"path", "url":"./source/modules/oe/graphql-base", "options": {"symlink": true}}'

docker-compose exec -T \
  php composer config repositories.oxid-esales/grapqhl-storefront \
  --json '{"type":"path", "url":"./source/modules/oe/graphql-storefront", "options": {"symlink": true}}'

docker-compose exec -T php composer require oxid-esales/graphql-base:* --no-update
docker-compose exec -T php composer require oxid-esales/graphql-storefront:* --no-update

docker-compose exec -T php composer update --no-interaction
docker-compose exec -T php php vendor/bin/reset-shop

docker-compose exec -T php bin/oe-console oe:module:install-configuration source/modules/oe/graphql-base
docker-compose exec -T php bin/oe-console oe:module:install-configuration source/modules/oe/graphql-storefront

docker-compose exec -T php bin/oe-console oe:module:activate oe_graphql_base
docker-compose exec -T php bin/oe-console oe:module:activate oe_graphql_storefront

docker-compose exec -T php vendor/bin/oe-eshop-doctrine_migration migrations:migrate

echo "Done!"