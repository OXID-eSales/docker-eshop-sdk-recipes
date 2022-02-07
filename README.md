# development-oxid-recipes
Oxid eShop setup recipes

## Prerequirements

1. Check if other docker project is stopped! If you have something running, ports may conflict and nothing will work as intended, just take a minute and stop everything before running this!

2. You should have docker and docker-compose installed on your machine.

3. It should be some Linux or Mac :) No idea if it will work with Windows at all.

4. The ``127.0.0.1 localhost.local`` should be added to /etc/hosts

## Installation instructions:

Clone the environment and recipes first
```
mkdir myNewShinyProject && cd myNewShinyProject
git clone https://github.com/Fresh-Advance/development.git .
git clone https://github.com/Fresh-Advance/development-oxid-recipes.git recipes/oxid-esales
```

Run the recipe, for example:
```
./recipes/oxid-esales/b-6.4.x-ce-dev/run.sh
```

## Recipe Specifics

Any recipe outcome can have its own specifics. Read carefully before breaking your leg :)

### b-6.4.x-Xe-dev instructions

Running old selenium tests examples:

```
# docker default run:
docker-compose exec -e SELENIUM_SERVER_IP=seleniumfirefox php vendor/bin/runtests-selenium

# run from the php container:
SELENIUM_SERVER_IP=seleniumfirefox vendor/bin/runtests-selenium

#run from the php container with specific group:
SELENIUM_SERVER_IP=seleniumfirefox vendor/bin/runtests-selenium AllTestsSelenium --group=sieg
```

Running codeception tests examples:

```
# docker default run:
docker-compose exec -e SELENIUM_SERVER_HOST=selenium -e BROWSER_NAME=chrome php vendor/bin/runtests-codeception

# run from the php container:
SELENIUM_SERVER_HOST=selenium BROWSER_NAME=chrome vendor/bin/runtests-codeception

#run from the php container with specific group:
SELENIUM_SERVER_HOST=selenium BROWSER_NAME=chrome vendor/bin/runtests-codeception --group=sieg
```

### b-6.4.x-ce-graphql-storefront-dev instructions

Running codeception tests examples:

```
# docker default run:
docker-compose exec \
-e ADDITIONAL_TEST_PATHS=vendor/oxid-esales/graphql-storefront/tests \
-e ACTIVATE_ALL_MODULES=1 \
-e RUN_TESTS_FOR_SHOP=0 \
-e RUN_TESTS_FOR_MODULES=0 \
php vendor/bin/runtests-codeception
```