#!/bin/bash

# Flags possible:
# -e for edition. Possible values: ce/pe/ee
# -m for metapackage repository //b-7.2 / b-8.0
# -b for shop repository branch //b-7.2.x / b-8.0.x

while getopts e:m:b: flag; do
  case "${flag}" in
  e) edition=${OPTARG} ;;
  m) metapackage=${OPTARG} ;;
  b) branch=${OPTARG} ;;
  *) echo "Invalid option"; exit 1 ;;
  esac
done

# Debugging: Print all the variables
echo "Edition: ${edition}"
echo "Metapackage: ${metapackage}"
echo "Branch: ${branch}"

if [ -z ${edition+x} ] || [ -z ${metapackage+x} ] || [ -z ${branch+x} ]; then
  echo -e "\e[1;31mThe edition (-e), metapackage (-m) and branch (-b) are required for require_compilation_base.sh\e[0m"
  exit 1
fi

# clone metapackage for composer.json file
git clone https://github.com/OXID-eSales/oxideshop_metapackage_"${edition}".git --branch="${metapackage}" source/

docker compose exec -T php composer remove oxid-esales/oxideshop-metapackage-ee --no-update
docker compose exec -T php composer remove oxid-esales/oxideshop-metapackage-pe --no-update
docker compose exec -T php composer remove oxid-esales/oxideshop-metapackage-ce --no-update

# Insert the "autoload-dev" section into composer.json
perl -pi -e '
    BEGIN {
        $inserted = 0;
        $autoload_dev = qq(  "autoload-dev": {\n    "psr-4": {\n      "OxidEsales\\\\EshopCommunity\\\\Tests\\\\": "./vendor/oxid-esales/oxideshop-ce/tests"\n    }\n  },\n);
    }
    if (!$inserted && $_ =~ /"repositories":/) {
        $_ = $autoload_dev . $_;
        $inserted = 1;
    }
' source/composer.json

# Insert the "config" section into composer.json
perl -pi -e '
    BEGIN {
        $inserted_config = 0;
        $config_section = qq(  "config": {\n    "github-protocols": ["https"],\n    "allow-plugins": {\n      "oxid-esales/oxideshop-composer-plugin": true,\n      "oxid-esales/oxideshop-unified-namespace-generator": true\n    },\n    "preferred-install": {\n      "oxid-esales/*": "source"\n    },\n    "optimize-autoloader": true\n  },\n);
    }
    if (!$inserted_config && $_ =~ /"repositories":/) {
        $_ = $config_section . $_;
        $inserted_config = 1;
    }
    END {
        if (!$inserted_config) {
            $_ .= $config_section;
        }
    }
' source/composer.json

# Remote URL for the `require-dev` section
REMOTE_URL="https://raw.githubusercontent.com/OXID-eSales/oxideshop_ce/${branch}/composer.json"
REMOTE_JSON=$(wget -qO- "$REMOTE_URL")

# Extract the require-dev section from the fetched content
REQUIRE_DEV=$(echo "$REMOTE_JSON" | perl -0777 -ne 'print $1 if /"require-dev"\s*:\s*(\{.*?\})/s')

if [ -z "$REQUIRE_DEV" ]; then
    echo "Failed to fetch require-dev section from remote URL."
    exit 1
fi

# Insert or update the require-dev section at the end of the composer.json file
perl -0777 -pi -e '
  BEGIN {
      $require_dev_section = qq(\n  "require-dev": '"$REQUIRE_DEV"'\n);
  }
  if ($_ =~ /\}\s*\n\s*\}$/s) {
      $_ =~ s/\}\s*\n\s*\}$/},$require_dev_section\n}/s;
  }
' source/composer.json