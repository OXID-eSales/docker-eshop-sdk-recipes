#!/bin/bash

# Flags possible:
# -n full package identifier, like oxid-esales/twig-admin
# -g git url like https://github.com/OXID-eSales/media-library-module.git
# -v package version like dev-b-7.0.x or ^v5.3.6

while getopts n:g:v: flag; do
  case "${flag}" in
  n) name=${OPTARG} ;;
  g) giturl=${OPTARG} ;;
  v) version=${OPTARG} ;;
  *) ;;
  esac
done

echo -e "\n\033[1;37m\033[1;42mRequire package ${name} with no update\033[0m"

if [ -z ${name+x} ] || [ -z ${version+x} ]; then
  echo -e "\e[1;31mThe package name(-n), its git url(-g) and version(-v) are required for require.sh\e[0m"
  exit 1
fi

if [ ${giturl+x} ]; then
  echo -e "\e[1;37mRegistering the package ${name} repository ${giturl}\e[0m"
  docker compose exec php composer config "repositories.${name}" git ${giturl}
fi

docker compose exec php composer require "${name}:${version}" --no-update