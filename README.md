# OXID eShop Setup Recipes

Recipes used together with https://github.com/OXID-eSales/docker-eshop-sdk for an OXID eShop development environment.

## Prerequirements

Check if other docker projects are stopped! If you have something running, ports may conflict and nothing will work as intended!

For recipes that involves private repositories, you will need the Github token which have access to those repositories.
In case Github credentials are asked, put your username and the **Github Token in place of password**!

Use other then **root** user, as composer and other parts of the system (like php container) may be very unhappy meeting one!

Also, consider preconfiguring the git authentication to be cached globally. It will help a lot with recipes where several private repositories are involved:
```
git config --global credential.helper cache
```

### Linux / MacOS

- Docker and Docker-Compose
- Makefile
- PERL. Try if you have it installed with `perl -v`
- `127.0.0.1 localhost.local` added to `/etc/hosts`

### Windows

- Windows Subsystem for Linux:
  - Install with `wsl --install -d Ubuntu`, reboot and add your Linux user
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
git clone --recurse-submodules https://github.com/OXID-eSales/docker-eshop-sdk-recipes recipes/oxid-esales
```

3. And last - run the desired recipe, for example:
```
./recipes/oxid-esales/shop/b-6.5.x-ce-dev/run.sh
```

## Parts directory is a submodule

The ``parts`` directory is used as a git submodule. It has its own repository for easier reuse between
different recipes.

To pull the latest changes from parts repository and update the link, you can use the following commands by being in the current repository root:

```
git submodule update --remote
git commit -am "Update parts submodule to latest"
```

Be careful with the changes in the parts repository, as they may affect all **recipes** using it.
Also be careful with pushing changes to the parts repository, as it may affect all **repositories** using it.

## Multiserver configuration

To experiment with multiserver configuration locally you can run either the full recipe example - ``shop/b-7.1.x-apex-multiserver.sh`` - or add the load balancing setup to an existing docker-compose.yml using ``parts/shared/create_multiserver_setup.sh``. This script will accept the ``-c=<some number>`` argument if you want to specify a number of frontend php containers. It will create two by default.

If you wish to run the part script on an existing docker configuration, you will need to manually cleanup the blocks for all services included in ``services/loadbalancer.yml`` as well as any numbered frontend containers if it has been run before in your setup.

## 6.4 recipes

The recipes for 6.4 modules are available in recipes b-6.4.x-branch. Please check it out, if you want to use those
recipes.

> **_NOTE:_** Don not forget that version 6.4 is not supported anymore.
