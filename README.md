# Recipe parts
Reciped parts for docker sdk recipes

## Synchronize parts

For the first time, its required the parts to be registered and merged:
```
git subtree add --prefix=parts https://github.com/OXID-eSales/docker-eshop-sdk-recipe-parts master
```

To pull new parts updates, in the recipes folder, do:
```
git subtree pull --prefix=parts https://github.com/OXID-eSales/docker-eshop-sdk-recipe-parts master
```

To push the update to parts, make a commit in your recipes repository as usual, and afterwards, do:
```
git subtree push --prefix=parts https://github.com/OXID-eSales/docker-eshop-sdk-recipe-parts master
```
