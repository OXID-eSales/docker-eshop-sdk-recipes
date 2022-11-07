#!/bin/bash

# Flags possible: -e for edition. Example: -eEE

edition="CE"
shop_flag=""

while getopts e: flag; do
  case "${flag}" in
  e) edition=${OPTARG} ;;
  esac
done

if [ $edition = "EE" ]; then
  shop_flag="--shop-id=1"
fi

docker-compose exec -T php bin/oe-console oe:database:reset --db-host=mysql --db-port=3306 --db-name=example --db-user=root --db-password=root ${shop_flag} --force
