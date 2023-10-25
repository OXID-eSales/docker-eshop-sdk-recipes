email=noreply@oxid-esales.com
password=admin

docker compose exec -T php bin/oe-console oe:admin:create --admin-email="$email" --admin-password="$password"

echo -e "\033[1;37m\033[1;42mCreate admin: Admin login: ${email} Password: ${password}\033[0m\n"
