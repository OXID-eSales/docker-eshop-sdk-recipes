#!/bin/bash

# Flags possible: -e for edition. Example: -eEE

edition="CE"

while getopts e: flag; do
  case "${flag}" in
  e) edition=${OPTARG} ;;
  esac
done

# Configure smarty components in composer
docker compose exec -T \
  php composer config repositories.oxid-esales/smarty-component \
  --json '{"type":"git", "url":"https://github.com/OXID-eSales/smarty-component"}'
docker compose exec -T php composer require oxid-esales/smarty-component:dev-b-7.0.x --no-update

# Smarty page objects
docker compose exec -T php composer require oxid-esales/codeception-page-objects:dev-b-7.0.x-SMARTY --no-update --dev

if [ $edition = "EE" ]; then
  docker compose exec -T \
    php composer config repositories.oxid-esales/smarty-component-pe \
    --json '{"type":"git", "url":"https://github.com/OXID-eSales/smarty-component-pe"}'
  docker compose exec -T php composer require oxid-esales/smarty-component-pe:dev-b-7.0.x --no-update

  docker compose exec -T \
    php composer config repositories.oxid-esales/smarty-component-ee \
    --json '{"type":"git", "url":"https://github.com/OXID-eSales/smarty-component-ee"}'
  docker compose exec -T php composer require oxid-esales/smarty-component-ee:dev-b-7.0.x --no-update
fi

# Clone smarty admin theme development versions
git clone https://github.com/OXID-eSales/smarty-admin-theme --branch=b-7.0.x source/source/Application/views/admin_smarty
docker compose exec -T \
  php composer config repositories.oxid-esales/smarty-admin-theme \
  --json '{"type":"path", "url":"./source/Application/views/admin_smarty", "options": {"symlink": false}}'
docker compose exec -T php composer require oxid-esales/smarty-admin-theme:dev-b-7.0.x --no-update

git clone https://github.com/OXID-eSales/flow_theme --branch=b-7.0.x source/source/Application/views/flow
docker compose exec -T \
  php composer config repositories.oxid-esales/flow-theme \
  --json '{"type":"path", "url":"./source/Application/views/flow", "options": {"symlink": false}}'
docker compose exec -T php composer require oxid-esales/flow-theme:dev-b-7.0.x --no-update

#Symlink theme out directory
cd source/source/out/
ln -s ../Application/views/flow/out/flow flow
cd -
