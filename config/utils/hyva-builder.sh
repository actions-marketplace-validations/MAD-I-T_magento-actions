#!/usr/bin/env bash

#set -e

IS_NODE_SET=0

echo "checking for hyva themes in - " $(pwd)
for file in app/design/frontend/*/*; do
  if [ -d "$file/web/tailwind" ]
  then
    PROJECT_NODE_VERSION=$(grep -o '"node": *"[^"]*"' $file/web/tailwind/package.json | sed 's/.*"node": *"\([^"]*\)".*/\1/' | sed 's/[^0-9]*\([0-9]\+\).*/\1/')

    if [ $IS_NODE_SET = 0 ]
    then
      curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.39.1/install.sh | bash
      export NVM_DIR="$HOME/.nvm"
      [ -s "$NVM_DIR/nvm.sh"  ] &&. "$NVM_DIR/nvm.sh"
      nvm install $PROJECT_NODE_VERSION
      IS_NODE_SET=1
    else
      nvm install $PROJECT_NODE_VERSION
      nvm use $PROJECT_NODE_VERSION
    fi
    mkdir -p "$file/web/css/"
    npm --prefix "$file/web/tailwind" ci

    SCRIPT_NAME="build"
    if grep -q "\"$SCRIPT_NAME\"" $file/web/tailwind/package.json; then
      npm --prefix "$file/web/tailwind" run build
    else
      npm --prefix "$file/web/tailwind" run build-prod
    fi

    # cleanup
    rm -rf "$file/web/tailwind/node_modules/"
  fi
done
rm -rf ~/.nvm/
