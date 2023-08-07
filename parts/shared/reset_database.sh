#!/bin/bash

echo -e "\033[1;37m\033[1;42mReset database\033[0m\n"

docker compose exec -T php bin/oe-console oe:database:reset --db-host=mysql --db-port=3306 --db-name=example --db-user=root --db-password=root --force