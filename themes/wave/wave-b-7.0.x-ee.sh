#!/bin/bash

SCRIPT_PATH=$(dirname ${BASH_SOURCE[0]})

cd $SCRIPT_PATH/../../../../ || exit

# Prepare services configuration
make setup
make addbasicservices
make file=services/adminer.yml addservice

$SCRIPT_PATH/../../parts/b-7.0.x/start_shop.sh -eEE
$SCRIPT_PATH/../../parts/b-7.0.x/require_smarty_components.sh -eEE

git clone https://github.com/OXID-eSales/wave-theme --branch=b-7.0.x source/source/Application/views/wave
docker-compose exec -T \
  php composer config repositories.oxid-esales/wave-theme \
  --json '{"type":"path", "url":"./source/Application/views/wave", "options": {"symlink": false}}'
docker-compose exec -T php composer require oxid-esales/wave-theme:dev-b-7.0.x --no-update

#Symlink theme out directory
cd source/source/out/
ln -s ../Application/views/wave/out/wave wave
cd -

# Require demodata package
docker-compose exec -T \
  php composer config repositories.oxid-esales/oxideshop-demodata-ee \
  --json '{"type":"git", "url":"https://github.com/OXID-eSales/oxideshop_demodata_ee"}'
docker-compose exec -T php composer require oxid-esales/oxideshop-demodata-ee:dev-master --no-update

# Install all preconfigured dependencies
docker-compose exec -T php composer update --no-interaction

$SCRIPT_PATH/../../parts/b-7.0.x/reset_database.sh -eEE
docker-compose exec -T php bin/oe-console oe:setup:demodata
docker-compose exec -T php bin/oe-console oe:admin:create --admin-email='admin@admin.com' --admin-password='admin'

echo "Done! Admin login: admin@admin.com Password: admin"
echo "Warning! - Activate Wave theme in Admin!!"