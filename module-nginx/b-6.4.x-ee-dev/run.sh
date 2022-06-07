#!/bin/bash

SCRIPT_PATH=$(dirname ${BASH_SOURCE[0]})

cd $SCRIPT_PATH/../../../../ || exit

git clone https://github.com/OXID-eSales/oxideshop_ce.git --branch=b-6.4.x source

# Prepare services configuration
make setup
make addbasicservices
make file=services/selenium-chrome.yml addservice

# Change Apache port and add nginx container
perl -pi\
  -e 's#- 80:80#- 8000:80#g;'\
  -e 's#apache:localhost.local#nginx:localhost.local#g;'\
  docker-compose.yml
make file=services/nginx-rp.yml addservice

# Add elasticsearch and kibana services
make file=services/elasticsearch.yml addservice

# Configure containers
perl -pi\
  -e 's#/var/www/#/var/www/source/#g;'\
  containers/httpd/project.conf

perl -pi\
  -e 's#display_errors = .*#display_errors = false#g;'\
  containers/php/custom.ini
perl -pi\
  -e "s#'display_errors', '1'#'display_errors', '0'#g;"\
  source/source/bootstrap.php

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

# Clone NGINX module to modules directory
git clone https://github.com/OXID-eSales/nginx-module --branch=b-6.4.x source/source/modules/oe/nginx

# Start all containers
make up

docker-compose exec php composer config github-protocols https
docker-compose exec php composer config repositories.oxid-esales/oxideshop-pe git https://github.com/OXID-eSales/oxideshop_pe.git
docker-compose exec php composer config repositories.oxid-esales/oxideshop-ee git https://github.com/OXID-eSales/oxideshop_ee.git
docker-compose exec php composer require oxid-esales/oxideshop-pe:dev-b-6.4.x --no-update
docker-compose exec php composer require oxid-esales/oxideshop-ee:dev-b-6.4.x --no-plugins --no-scripts

docker-compose exec php composer require oxid-esales/wave-theme:dev-b-1.x --no-update

# Configure modules in composer
docker-compose exec -T \
  php composer config repositories.oxid-esales/nginx-module \
  --json '{"type":"path", "url":"./source/modules/oe/nginx", "options": {"symlink": true}}'
docker-compose exec -T php composer require oxid-esales/nginx-module:* --no-update

docker-compose exec -T php composer update --no-interaction
docker-compose exec -T php php vendor/bin/reset-shop

docker-compose exec -T php bin/oe-console oe:module:install-configuration source/modules/oe/nginx/

mkdir -p ./source/var/configuration/environment
cp $SCRIPT_PATH/environment/1.yaml ./source/var/configuration/environment/1.yaml
docker-compose exec -T php bin/oe-console oe:module:apply-configuration

docker-compose exec -T php bin/oe-console oe:module:activate oenginx

echo "Done!"