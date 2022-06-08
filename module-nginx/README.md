# NGINX Module related recipes

### Test running

Running unit+integration tests

```
docker-compose exec \
    -e PARTIAL_MODULE_PATHS=oe/nginx \
    -e ADDITIONAL_TEST_PATHS=vendor/oxid-esales/nginx-module/tests \
    -e ACTIVATE_ALL_MODULES=1 \
    -e RUN_TESTS_FOR_SHOP=0 \
    -e RUN_TESTS_FOR_MODULES=0 \
    php vendor/bin/runtests
```

Running unit+integration tests with coverage

```
docker-compose exec \
    -e PARTIAL_MODULE_PATHS=oe/nginx \
    -e ADDITIONAL_TEST_PATHS=vendor/oxid-esales/nginx-module/tests \
    -e ACTIVATE_ALL_MODULES=1 \
    -e RUN_TESTS_FOR_SHOP=0 \
    -e RUN_TESTS_FOR_MODULES=0 \
    -e XDEBUG_MODE=coverage \
    php vendor/bin/runtests \
        --coverage-html=/var/www/coverage \
        AllTestsUnit
```

Running codeception tests:

```
docker-compose exec \
-e PARTIAL_MODULE_PATHS=oe/nginx \
-e ADDITIONAL_TEST_PATHS=vendor/oxid-esales/nginx-module/tests \
-e ACTIVATE_ALL_MODULES=1 \
-e RUN_TESTS_FOR_SHOP=0 \
-e RUN_TESTS_FOR_MODULES=0 \
php vendor/bin/runtests-codeception
```

### Other tools

Accessing kibana to play and manage your elasticsearch data: `http://localhost.local:5601`