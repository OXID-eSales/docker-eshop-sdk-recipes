#!/bin/bash

# Flags possible: -e for edition. Example: -eEE

update="false"

while getopts e:u:b: flag; do
  case "${flag}" in
  e) edition=${OPTARG} ;;
  b) branch=${OPTARG} ;;
  u) update=${OPTARG} ;;
  *) ;;
  esac
done

echo -e "\033[1;37m\033[1;42mPrepare shop package: Edition: ${edition}, Branch: ${branch}\033[0m\n"

if [ -z ${edition+x} ] || [ -z ${branch+x} ]; then
  echo -e "\e[1;31mThe edition (-e) and branch (-b) are required for checkout_shop_edition.sh\e[0m"
  exit 1
fi

perl -pi\
  -e 's#/var/www/#/var/www/source/#g;'\
  containers/httpd/project.conf

git clone https://github.com/OXID-eSales/oxideshop_ce.git --branch=${branch} source

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
  docker compose exec php composer require oxid-esales/oxideshop-pe:dev-${branch} --no-update
fi

if [ $edition = "EE" ]; then
  docker compose exec \
    php composer config repositories.oxid-esales/oxideshop-pe \
    --json '{"type":"git", "url":"https://github.com/OXID-eSales/oxideshop_pe"}'
  docker compose exec php composer require oxid-esales/oxideshop-pe:dev-${branch} --no-update

  docker compose exec \
    php composer config repositories.oxid-esales/oxideshop-ee \
    --json '{"type":"git", "url":"https://github.com/OXID-eSales/oxideshop_ee"}'
  docker compose exec php composer require oxid-esales/oxideshop-ee:dev-${branch} --no-update
fi

docker compose exec -T php composer config preferred-install.oxid-esales/* source

if [ $update = true ]; then
  docker compose exec php composer update --no-plugins --no-scripts
fi
