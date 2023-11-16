#!/bin/bash

# Set number of frontend containers to be configured

containers=2

while getopts c: flag; do
  case "${flag}" in
  c) containers=${OPTARG} ;;
  *) ;;
  esac
done

# Cleanup any previous configs

rm -f containers/loadbalancer/loadbalancer.conf

for dir in containers/httpd-frontend-*; do
    if [ -d "$dir" ]; then
        rm -rf "$dir"
    fi
done

# Add new configuration

cp -n containers/loadbalancer/loadbalancer.conf.dist containers/loadbalancer/loadbalancer.conf

nginxcontainers=''
composecontainers=''

make file=services/mysql.yml addservice
make file=recipes/oxid-esales/services/loadbalancer.yml addservice

for number in $( seq 1 $containers )
do
  cp -rn containers/httpd/ "containers/httpd-frontend-${number}"

  if [ ! -f containers/httpd-frontend-${number}/project.conf ]
    then
    cp -n "containers/httpd-frontend-${number}/project.conf.dist" "containers/httpd-frontend-${number}/project.conf"

    perl -pi\
      -e "s#/var/www/#/var/www/source/#g;"\
      "containers/httpd-frontend-${number}/project.conf"
  fi

  perl -pi\
    -e "s#proxy:fcgi://php#proxy:fcgi://php-frontend-${number}#g;"\
    "containers/httpd-frontend-${number}/custom.conf"

  make file=recipes/oxid-esales/services/php-frontend.yml addservice

  perl -pi\
    -e "s#<NUMBER>#${number}#g;"\
    "docker-compose.yml"

  nginxcontainers+="    server apache-frontend-${number}:80;"$'\n'
  composecontainers+="      - apache-frontend-${number}"$'\n'
done

perl -pi \
  -e "s#<FRONTEND-SERVERS>#${nginxcontainers}#g;"\
  containers/loadbalancer/loadbalancer.conf

perl -pi \
  -e "s#<FRONTEND-APACHE-CONTAINERS>#${composecontainers}#g;"\
  docker-compose.yml