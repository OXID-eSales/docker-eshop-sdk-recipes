email=admin@admin.com
password=admin

docker-compose exec -T php bin/oe-console oe:admin:create --admin-email="$email" --admin-password="$password"

echo "Admin login: $email Password: $password"
