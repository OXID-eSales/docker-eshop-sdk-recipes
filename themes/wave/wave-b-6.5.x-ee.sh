#!/bin/bash

SCRIPT_PATH=$(dirname ${BASH_SOURCE[0]})

cd $SCRIPT_PATH/../../../../ || exit

git clone https://github.com/OXID-eSales/oxideshop_ce.git --branch=b-6.5.x source

make setup
make addbasicservices
make file=services/adminer.yml addservice

# Configure containers
perl -pi\
  -e 's#/var/www/#/var/www/source/#g;'\
  containers/httpd/project.conf

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

docker-compose exec php composer config github-protocols https
docker-compose exec php composer config repositories.oxid-esales/oxideshop-ee git https://github.com/OXID-eSales/oxideshop_ee.git
docker-compose exec php composer config repositories.oxid-esales/oxideshop-pe git https://github.com/OXID-eSales/oxideshop_pe.git

docker-compose exec php composer require oxid-esales/oxideshop-pe:dev-b-6.5.x --no-update
docker-compose exec php composer require oxid-esales/oxideshop-ee:dev-b-6.5.x --no-plugins --no-scripts

git clone https://github.com/OXID-eSales/wave-theme --branch=b-1.x source/source/Application/views/wave
docker-compose exec -T \
  php composer config repositories.oxid-esales/wave-theme \
  --json '{"type":"path", "url":"./source/Application/views/wave", "options": {"symlink": false}}'
docker-compose exec -T php composer require oxid-esales/wave-theme:* --no-update

#Symlink theme out directory
cd source/source/out/
ln -s ../Application/views/wave/out/wave wave
cd -

docker-compose exec -T php composer update --no-interaction
docker-compose exec -T php php vendor/bin/reset-shop

echo "Warning! - Activate Wave theme in Admin!!"
echo "Done!"