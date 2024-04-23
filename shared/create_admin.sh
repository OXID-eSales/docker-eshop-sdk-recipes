email=noreply@oxid-esales.com
password=admin
CONSOLE_PATH=$( [ -e "source/bin/oe-console" ] && echo "bin/oe-console" || echo "vendor/bin/oe-console" )

docker compose exec -T php ${CONSOLE_PATH} oe:admin:create --admin-email="$email" --admin-password="$password"

echo -e "\033[1;37m\033[1;42mCreate admin: Admin login: ${email} Password: ${password}\033[0m\n"
