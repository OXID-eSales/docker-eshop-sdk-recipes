# Recipe parts
Reciped parts for docker sdk recipes

## Synchronize parts

To pull new parts updates, in the recipes folder, do:
```
git subtree pull --prefix=parts https://github.com/OXID-eSales/docker-eshop-sdk-recipe-parts master
```

To push the update to parts, make a commit in your recipes repository as usual, and afterwards, do:
```
git subtree push --prefix=parts https://github.com/OXID-eSales/docker-eshop-sdk-recipe-parts master
```
