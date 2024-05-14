#!/bin/bash
# Flags possible:
# -e for shop edition. Possible values: CE/EE

edition='CE'
while getopts e: flag; do
  case "${flag}" in
  e) edition=${OPTARG} ;;
  *) ;;
  esac
done

SCRIPT_PATH=$(dirname ${BASH_SOURCE[0]})

cd $SCRIPT_PATH/../../../ || exit

# Prepare services configuration
make setup
make addbasicservices
make file=services/adminer.yml addservice
make file=services/selenium-chrome.yml addservice

# Configure containers
perl -pi\
  -e 's#error_reporting = .*#error_reporting = E_ALL ^ E_WARNING ^ E_DEPRECATED#g;'\
  containers/php/custom.ini

perl -pi\
  -e 's#/var/www/#/var/www/source/#g;'\
  containers/httpd/project.conf

perl -pi\
  -e 's#PHP_VERSION=.*#PHP_VERSION=8.1#g;'\
  .env

mkdir source
docker compose up --build -d php

cp ${SCRIPT_PATH}/../parts/bases/composer.json.base ./source/composer.json

$SCRIPT_PATH/../parts/shared/require_shop_edition_packages.sh -e"${edition}" -v"dev-b-7.1.x"
$SCRIPT_PATH/../parts/shared/require_twig_components.sh -e"${edition}" -b"b-7.1.x"
$SCRIPT_PATH/../parts/shared/require.sh -n"oxid-esales/developer-tools" -v"dev-b-7.1.x"
$SCRIPT_PATH/../parts/shared/require.sh -n"oxid-esales/apex-theme" -v"dev-b-7.1.x"
$SCRIPT_PATH/../parts/shared/require.sh -n"oxid-esales/geo-blocking-module" -g"https://github.com/OXID-eSales/geo-blocking-module.git" -v"dev-b-7.1.x"

docker compose exec php composer update --no-interaction

perl -pi\
  -e 'print "SetEnvIf Authorization \"(.*)\" HTTP_AUTHORIZATION=\$1\n\n" if $. == 1'\
  source/source/.htaccess

make up

$SCRIPT_PATH/../parts/shared/setup_database.sh --no-demodata

docker compose exec -T php vendor/bin/oe-console oe:module:activate oegeoblocking
docker compose exec -T php vendor/bin/oe-console oe:theme:activate apex

$SCRIPT_PATH/../parts/shared/create_admin.sh

# Register all related project packages git repositories
mkdir -p .idea; mkdir -p source/.idea; cp "${SCRIPT_PATH}/../parts/bases/vcs.xml.base" .idea/vcs.xml
perl -pi\
  -e 's#</component>#<mapping directory="\$PROJECT_DIR\$/source/vendor/oxid-esales/oxideshop-ce" vcs="Git" />\n  </component>#g;'\
  -e 's#</component>#<mapping directory="\$PROJECT_DIR\$/source/vendor/oxid-esales/oxideshop-pe" vcs="Git" />\n  </component>#g;'\
  -e 's#</component>#<mapping directory="\$PROJECT_DIR\$/source/vendor/oxid-esales/oxideshop-ee" vcs="Git" />\n  </component>#g;'\
  -e 's#</component>#<mapping directory="\$PROJECT_DIR\$/source/vendor/oxid-esales/geo-blocking-module" vcs="Git" />\n  </component>#g;'\
  .idea/vcs.xml
cp .idea/vcs.xml source/.idea/vcs.xml; perl -pi -e 's#/source/vendor/#/vendor/#g;' source/.idea/vcs.xml