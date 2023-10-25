SHARED_SCRIPT_PATH=$(dirname $0)
DEMODATA=1

#Pass arguments to the script
flags()
{
    while test $# -gt 0
    do
        case "$1" in
        -n|--no-demodata)
            DEMODATA=0
            ;;
        esac

        # and here we shift to the next argument
        shift
    done
}
flags "$@"

echo -e "\033[1;37m\033[1;42mSetup shop\033[0m\n"

docker compose exec php bin/oe-console oe:setup:shop --db-host=mysql --db-port=3306 --db-name=example --db-user=root \
  --db-password=root --shop-url=http://localhost.local/ --shop-directory=/var/www/source/ \
  --compile-directory=/var/www/source/tmp/

$SHARED_SCRIPT_PATH/reset_database.sh

if [[ $DEMODATA -eq 1 ]]; then
  docker compose exec -T php bin/oe-console oe:setup:demodata
fi
