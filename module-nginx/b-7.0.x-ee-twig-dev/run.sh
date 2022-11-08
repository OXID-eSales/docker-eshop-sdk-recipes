#!/bin/bash

SCRIPT_PATH=$(dirname ${BASH_SOURCE[0]})

cd $SCRIPT_PATH/../../../../ || exit

git clone https://github.com/OXID-eSales/oxideshop_ce.git --branch=b-7.0.x source

# Prepare services configuration
make setup
make addbasicservices
make file=services/selenium-chrome.yml addservice
make file=services/selenium-firefox.yml addservice

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
  -e 's#error_reporting = .*#error_reporting = E_ALL ^ E_WARNING ^ E_DEPRECATED#g;'\
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
  -e 's#iDebug = 0;#iDebug = -1;#g;'\
  source/source/config.inc.php

# Clone NGINX module to modules directory
git clone https://github.com/OXID-eSales/nginx-module --branch=master source/source/modules/oe/nginx

# Start all containers
make up

# Update composer to 2.4+
docker-compose exec php sudo composer self-update --2

docker-compose exec php composer config github-protocols https
docker-compose exec php composer config repositories.oxid-esales/oxideshop-pe git https://github.com/OXID-eSales/oxideshop_pe.git
docker-compose exec php composer config repositories.oxid-esales/oxideshop-ee git https://github.com/OXID-eSales/oxideshop_ee.git
docker-compose exec php composer require oxid-esales/oxideshop-pe:dev-b-7.0.x --no-update
docker-compose exec php composer require oxid-esales/oxideshop-ee:dev-b-7.0.x --no-plugins --no-scripts

## deprecated tests
docker-compose exec php composer config repositories.oxid-esales/tests-deprecated-pe git https://github.com/OXID-eSales/tests-deprecated-pe.git
docker-compose exec php composer config repositories.oxid-esales/tests-deprecated-ee git https://github.com/OXID-eSales/tests-deprecated-ee.git
docker-compose exec php composer require oxid-esales/tests-deprecated-ce:dev-b-7.0.x --no-update
docker-compose exec php composer require oxid-esales/tests-deprecated-pe:dev-b-7.0.x --no-update
docker-compose exec php composer require oxid-esales/tests-deprecated-ee:dev-b-7.0.x --no-update

docker-compose exec php composer config repositories.oxid-esales/twig-component-pe git https://github.com/OXID-eSales/twig-component-pe.git
docker-compose exec php composer config repositories.oxid-esales/twig-component-ee git https://github.com/OXID-eSales/twig-component-ee.git
docker-compose exec php composer require oxid-esales/twig-component:dev-b-7.0.x --no-update
docker-compose exec php composer require oxid-esales/twig-component-pe:dev-b-7.0.x --no-update
docker-compose exec php composer require oxid-esales/twig-component-ee:dev-b-7.0.x --no-update
docker-compose exec php composer require oxid-esales/twig-admin-theme:dev-b-7.0.x --no-update
docker-compose exec php composer require oxid-esales/twig-theme:dev-b-7.0.x --no-update
docker-compose exec php composer require symfony/dotenv:^5.1 --no-update

# Configure modules in composer
docker-compose exec -T \
  php composer config repositories.oxid-esales/nginx-module \
  --json '{"type":"path", "url":"./source/modules/oe/nginx", "options": {"symlink": true}}'
docker-compose exec -T php composer require oxid-esales/nginx-module:* --no-update

docker-compose exec -T \
  php composer config repositories.oxid-esales/oxideshop-demodata-ee \
  --json '{"type":"git", "url":"https://github.com/OXID-eSales/oxideshop_demodata_ee"}'
docker-compose exec -T php composer require oxid-esales/oxideshop-demodata-ee:dev-master --no-update

docker-compose exec -T php composer update --no-interaction
docker-compose exec -T php bin/oe-console oe:database:reset --db-host=mysql --db-port=3306 --db-name=example --db-user=root --db-password=root --shop-id=1 --force
docker-compose exec -T php bin/oe-console oe:setup:demodata

mkdir -p ./source/var/configuration/environment/shops/1/modules
cp $SCRIPT_PATH/environment/oenginx.yaml ./source/var/configuration/environment/shops/1/modules/oenginx.yaml

docker-compose exec -T php bin/oe-console oe:module:activate oenginx

docker-compose exec -T php bin/oe-console oe:admin:create --admin-email='admin@admin.com' --admin-password='admin'

echo "Done! Admin login: admin@admin.com Password: admin"