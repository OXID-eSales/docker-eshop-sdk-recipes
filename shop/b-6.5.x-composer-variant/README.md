# Install the shop from composer file

## Recipe usage

Preparations required:

1. Run ``make setup`` and configure your prefered containers versions in ``.env`` file
2. Put any shop composer.json file near by the recipe
3. Optionally put any shops_1.yaml near by the recipe. This way it is possible to force the class extend chains. 
4. Optionally put any environment_1.yaml near by the recipe.

Afterward:

5. Run the ``run.sh`` script

## NOTES
- The most commonly needed repositories are registered by ``run.sh`` script 