#!/bin/bash

SCRIPT_PATH=$(dirname ${BASH_SOURCE[0]})

cd $SCRIPT_PATH/../../../../../ || exit

mkdir source
mkdir source/source
cp $SCRIPT_PATH/composer.json source/

git clone https://github.com/OXID-eSales/oxideshop_metapackage_ce.git --branch=b-6.5 source/oxideshop_metapackage_ce
cp $SCRIPT_PATH/ce_metapackage.composer.json source/oxideshop_metapackage_ce/composer.json

make setup
make addbasicservices
make file=services/adminer.yml addservice
make file=services/selenium-chrome.yml addservice
make file=recipes/oxid-esales/services/selenium-firefox-old.yml addservice

# Configure containers
perl -pi\
  -e 's#/var/www/#/var/www/source/#g;'\
  containers/httpd/project.conf

# Start all containers
make up

#register repositories
docker compose exec php sudo composer self-update --2 --stable
docker compose exec php composer config github-protocols https

docker compose exec \
  php composer config repositories.oxid-esales/oxideshop-demodata-ee \
  --json '{"type":"vcs", "url":"https://github.com/OXID-eSales/oxideshop_demodata_ee.git"}'
docker compose exec \
  php composer config repositories.oxid-esales/oxideshop-demodata-pe \
  --json '{"type":"vcs", "url":"https://github.com/OXID-eSales/oxideshop_demodata_pe.git"}'
docker compose exec \
  php composer config repositories.oxid-esales/oxideshop-ee \
  --json '{"type":"vcs", "url":"https://github.com/OXID-eSales/oxideshop_ee.git"}'
docker compose exec \
  php composer config repositories.oxid-esales/oxideshop-pe \
  --json '{"type":"vcs", "url":"https://github.com/OXID-eSales/oxideshop_pe.git"}'
docker compose exec \
  php composer config repositories.oxid-esales/oxideshop-metapackage-ee \
  --json '{"type":"vcs", "url":"https://github.com/OXID-eSales/oxideshop_metapackage_ee.git"}'
docker compose exec \
  php composer config repositories.oxid-esales/oxideshop-metapackage-pe \
  --json '{"type":"vcs", "url":"https://github.com/OXID-eSales/oxideshop_metapackage_pe.git"}'
docker compose exec \
  php composer config repositories.ddoe/visualcms-module \
  --json '{"type":"vcs", "url":"https://github.com/OXID-eSales/visual_cms_module.git"}'
docker compose exec \
  php composer config repositories.oxid-solution-catalysts/unzer \
  --json '{"type":"vcs", "url":"https://github.com/OXID-eSales/unzer-module.git"}'

docker compose exec php composer update --working-dir=oxideshop_metapackage_ce
docker compose exec php composer update

# Configure shop
cp source/source/config.inc.php.dist source/source/config.inc.php

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

docker compose exec -T php rm -rf source/tmp
docker compose exec -T php mkdir source/tmp

if [ -f $SCRIPT_PATH/shops_1.yaml ]; then cp -f $SCRIPT_PATH/shops_1.yaml source/var/configuration/shops/1.yaml; fi
if [ -f $SCRIPT_PATH/environment_1.yaml ]; then
  mkdir source/var/configuration/environment;
  cp -fp $SCRIPT_PATH/environment_1.yaml source/var/configuration/environment/1.yaml;
fi
docker compose exec -T php php vendor/bin/reset-shop

echo "Done!"