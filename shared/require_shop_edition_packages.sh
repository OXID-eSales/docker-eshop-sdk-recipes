#!/bin/bash

SHARED_SCRIPT_PATH=$(dirname $0)

# Flags possible:
#   -e for edition, example: -e"EE"
#   -v for version, example: -v"dev-b-7.0.x" or -v"^7.0.0"

while getopts e:v: flag; do
  case "${flag}" in
  e) edition=${OPTARG} ;;
  v) version=${OPTARG} ;;
  *) ;;
  esac
done

echo -e "\033[1;37m\033[1;42mRequire shop edition package: Edition: ${edition}, Branch: ${version}\033[0m\n"

if [ -z ${edition+x} ] || [ -z ${version+x} ]; then
  echo -e "\e[1;31mThe edition (-e) and version (-v) are required for require_shop_edition_packages.sh\e[0m"
  exit 1
fi

$SHARED_SCRIPT_PATH/require.sh -n"oxid-esales/oxideshop-ce" -g"https://github.com/OXID-eSales/oxideshop_ce.git" -v${version}

if [ $edition = "PE" ]; then
  $SHARED_SCRIPT_PATH/require.sh -n"oxid-esales/oxideshop-pe" -g"https://github.com/OXID-eSales/oxideshop_pe.git" -v${version}
fi

if [ $edition = "EE" ]; then
  $SHARED_SCRIPT_PATH/require.sh -n"oxid-esales/oxideshop-pe" -g"https://github.com/OXID-eSales/oxideshop_pe.git" -v${version}
  $SHARED_SCRIPT_PATH/require.sh -n"oxid-esales/oxideshop-ee" -g"https://github.com/OXID-eSales/oxideshop_ee.git" -v${version}
fi
