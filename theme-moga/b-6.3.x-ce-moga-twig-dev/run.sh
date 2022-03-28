#!/bin/bash

SCRIPT_PATH=$(dirname ${BASH_SOURCE[0]})

cd $SCRIPT_PATH/../../../../ || exit

git clone git@github.com:OXID-eSales/oxideshop_ce.git --branch=b-6.3.x source

# Prepare services configuration
make setup
make addbasicservices

#change php version to 7.4
perl -pi\
  -e 's#PHP_VERSION=.*#PHP_VERSION="7.4"#g;'\
  .env

# Configure containers
perl -pi\
  -e 'print "xdebug.max_nesting_level=1000\n" if $. == 1'\
  containers/php/custom.ini

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

# Clone Moga twig theme to themes directory
git clone git@github.com:OXID-eSales/moga-twig-theme.git --branch=main source/source/Application/views/moga-twig

# Start all containers
make up

# Configure modules in composer
docker-compose exec -T \
  php composer config repositories.oxid-esales/moga-twig-theme \
  --json '{"type":"path", "url":"./source/Application/views/moga-twig", "options": {"symlink": true}}'

# Add twig-component and themes
docker-compose exec -T php composer require oxid-esales/twig-component
docker-compose exec -T php composer require oxid-esales/twig-admin-theme
docker-compose exec -T php composer require oxid-esales/moga-twig-theme:* --no-update

# Run dependencies installation and reset the shop to development state
docker-compose exec -T php composer update --no-interaction
docker-compose exec -T php php vendor/bin/reset-shop

#Symlink /out/moga-twig
cd source/source/Application/views

ln -s ../Application/views/moga-twig/out/moga-twig/ ../../out/moga-twig

echo "Recipe done! Activate the Moga theme in the Admin panel!!"
