# NGINX Module related recipes

### Test running

Running unit+integration tests

```
docker-compose exec \
-e ADDITIONAL_TEST_PATHS=vendor/oxid-esales/nginx-module/Tests \
-e ACTIVATE_ALL_MODULES=1 \
-e RUN_TESTS_FOR_SHOP=0 \
-e RUN_TESTS_FOR_MODULES=0 \
php vendor/bin/runtests
```

Running codeception tests:

```
docker-compose exec \
-e ADDITIONAL_TEST_PATHS=vendor/oxid-esales/nginx-module/Tests \
-e ACTIVATE_ALL_MODULES=1 \
-e RUN_TESTS_FOR_SHOP=0 \
-e RUN_TESTS_FOR_MODULES=0 \
php vendor/bin/runtests-codeception
```