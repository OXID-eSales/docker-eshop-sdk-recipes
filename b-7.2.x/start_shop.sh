#!/bin/bash

# Flags possible: -e for edition. Example: -eEE

edition="CE"
update="true"

while getopts e:u: flag; do
  case "${flag}" in
  e) edition=${OPTARG} ;;
  u) update=${OPTARG} ;;
  *) ;;
  esac
done

git clone https://github.com/OXID-eSales/oxideshop_ce.git --branch=b-7.2.x source

# Configure containers
perl -pi\
  -e 's#error_reporting = .*#error_reporting = E_ALL ^ E_WARNING ^ E_DEPRECATED#g;'\
  containers/php/custom.ini

perl -pi\
  -e 's#/var/www/#/var/www/source/#g;'\
  containers/httpd/project.conf

# Configure shop
cp source/source/config.inc.php.dist source/source/config.inc.php

perl -pi\
  -e 'print "SetEnvIf Authorization \"(.*)\" HTTP_AUTHORIZATION=\$1\n\n" if $. == 1'\
  source/source/.htaccess


# Start all containers
make up

if [ $edition = "PE" ]; then
  docker compose exec \
    php composer config repositories.oxid-esales/oxideshop-pe \
    --json '{"type":"git", "url":"https://github.com/OXID-eSales/oxideshop_pe"}'
  docker compose exec php composer require oxid-esales/oxideshop-pe:dev-b-7.2.x --no-update
fi

if [ $edition = "EE" ]; then
  docker compose exec \
    php composer config repositories.oxid-esales/oxideshop-pe \
    --json '{"type":"git", "url":"https://github.com/OXID-eSales/oxideshop_pe"}'
  docker compose exec php composer require oxid-esales/oxideshop-pe:dev-b-7.2.x --no-update

  docker compose exec \
    php composer config repositories.oxid-esales/oxideshop-ee \
    --json '{"type":"git", "url":"https://github.com/OXID-eSales/oxideshop_ee"}'
  docker compose exec php composer require oxid-esales/oxideshop-ee:dev-b-7.2.x --no-update
fi

if [ $update = true ]; then
  docker compose exec php composer update --no-plugins --no-scripts
fi
