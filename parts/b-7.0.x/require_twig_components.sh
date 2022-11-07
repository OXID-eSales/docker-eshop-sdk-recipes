#!/bin/bash

# Flags possible: -e for edition. Example: -eEE

edition="CE"

while getopts e: flag; do
  case "${flag}" in
  e) edition=${OPTARG} ;;
  esac
done

# Configure twig themes in composer
docker-compose exec -T \
  php composer config repositories.oxid-esales/twig-component \
  --json '{"type":"git", "url":"https://github.com/OXID-eSales/twig-component"}'
docker-compose exec -T php composer require oxid-esales/twig-component:dev-b-7.0.x --no-update

if [ $edition = "EE" ]; then
  docker-compose exec -T \
    php composer config repositories.oxid-esales/twig-component-pe \
    --json '{"type":"git", "url":"https://github.com/OXID-eSales/twig-component-pe"}'
  docker-compose exec -T php composer require oxid-esales/twig-component-pe:dev-b-7.0.x --no-update

  docker-compose exec -T \
    php composer config repositories.oxid-esales/twig-component-ee \
    --json '{"type":"git", "url":"https://github.com/OXID-eSales/twig-component-ee"}'
  docker-compose exec -T php composer require oxid-esales/twig-component-ee:dev-b-7.0.x --no-update
fi

# Clone twig theme development versions
git clone https://github.com/OXID-eSales/twig-admin-theme --branch=b-7.0.x source/source/Application/views/admin_twig
docker-compose exec -T \
  php composer config repositories.oxid-esales/twig-admin-theme \
  --json '{"type":"path", "url":"./source/Application/views/admin_twig", "options": {"symlink": false}}'
docker-compose exec -T php composer require oxid-esales/twig-admin-theme:dev-b-7.0.x --no-update

git clone https://github.com/OXID-eSales/twig-theme --branch=b-7.0.x source/source/Application/views/twig
docker-compose exec -T \
  php composer config repositories.oxid-esales/twig-theme \
  --json '{"type":"path", "url":"./source/Application/views/twig", "options": {"symlink": false}}'
docker-compose exec -T php composer require oxid-esales/twig-theme:dev-b-7.0.x --no-update

#Symlink theme out directory
cd source/source/out/
ln -s ../Application/views/twig/out/twig twig
cd -
