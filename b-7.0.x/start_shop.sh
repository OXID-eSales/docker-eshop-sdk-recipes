#!/bin/bash

# Flags possible: -e for edition. Example: -eEE

edition="CE"

while getopts e: flag; do
  case "${flag}" in
  e) edition=${OPTARG} ;;
  esac
done

# Start all containers
make up

# Update composer to 2.4+
docker-compose exec php sudo composer self-update --2

if [ $edition = "EE" ]; then
  docker-compose exec \
    php composer config repositories.oxid-esales/oxideshop-pe \
    --json '{"type":"git", "url":"https://github.com/OXID-eSales/oxideshop_pe"}'
  docker-compose exec php composer require oxid-esales/oxideshop-pe:dev-b-7.0.x --no-update

  docker-compose exec \
    php composer config repositories.oxid-esales/oxideshop-ee \
    --json '{"type":"git", "url":"https://github.com/OXID-eSales/oxideshop_ee"}'
  docker-compose exec php composer require oxid-esales/oxideshop-ee:dev-b-7.0.x --no-update
fi

# Install editions
docker-compose exec php composer update --no-plugins --no-scripts
