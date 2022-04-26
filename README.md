# OXID eShop Setup Recipes

Recipes used together with https://github.com/OXID-eSales/docker-eshop-sdk for an OXID eShop development environment.

## Prerequirements

Check if other docker projects are stopped! If you have something running, ports may conflict and nothing will work as intended!

For recipes that involves private repositories, you will need the Github token which have access to those repositories.
In case Github credentials are asked, put your username and the **Github Token in place of password**!

### Linux / MacOS

- Docker and Docker-Compose
- Makefile
- PERL. Try if you have it installed with `perl -v`
- `127.0.0.1 localhost.local` added to `/etc/hosts`

### Windows

- Windows Subsystem for Linux:
  - Install with `wsl --install`, reboot and add your Linux user
  - Update with `sudo apt update && apt upgrade`
  - Install Makefile with `sudo apt install make`
- Docker Desktop for Windows with WSL2 backend enabled
- `127.0.0.1 localhost.local` added to `%windir%\system32\drivers\etc\hosts`

## Installation instructions:

1. Clone the SDK to ``MyProject`` directory in this case:
```
echo MyProject && git clone https://github.com/OXID-eSales/docker-eshop-sdk.git $_ && cd $_
```

2. Clone recipes
```
git clone https://github.com/OXID-eSales/docker-eshop-sdk-recipes recipes/oxid-esales
```

3. And last - run the desired recipe, for example:
```
./recipes/oxid-esales/shop/b-6.4.x-ce-dev/run.sh
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

#run single test file from the php container:
SELENIUM_SERVER_IP=seleniumfirefox php vendor/bin/runtests-selenium --filter MyTest:: AllTestsSelenium
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

### Moga themes

Additional action required after the recipe is done:
* Activate the moga theme in admin.

The 7.0.x shop is not yet working with moga theme.