# Install the shop from composer file

## Recipe usage

Preparations required:

1. Configure your preferred containers versions in ``.env`` file.
2. Put any shop `composer.json` file into the recipe folder.
3. Put any ce metapackage ce `composer.json` file into the recipe folder and rename it to `ce_metapackage.composer.json`.
4. Optionally put any `shops_1.yaml` into the recipe folder. This way it is possible to force the class extend chains. 
5. Optionally put any `environment_1.yaml` into the recipe folder.

Afterward:

6. Run the ``run.sh`` script

## NOTES
- The most commonly needed repositories are registered by ``run.sh`` script