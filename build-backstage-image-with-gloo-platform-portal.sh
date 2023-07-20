#!/bin/sh

# Check that a Docker tag has been passed.

if [ -z "$1" ]
then
   echo "Please pass a tag that will be used for the Backstage Docker image as an argument to this script."
   exit 1
fi

DOCKER_IMAGE_TAG=$1

echo "Source nvm.sh to make nvm available to our script.\n"
. ~/.nvm/nvm.sh

echo "Set NVM version.\n"

# yarn set version 1.22.19
nvm use 18

echo "Delete backstage application directory if it exists.\n"
rm -rf backstage

echo "Bootstrap backstage project.\n"
npx @backstage/create-app@latest

pushd backstage

echo "Backing up original app-config.yaml file.\n"
cp app-config.yaml app-config.yaml.orig

echo "Patching app-config.yaml file to switch of insecure request upgrades for demo purposes.\n"
yq -i '.backend.csp += {"upgrade-insecure-requests": false}' app-config.yaml

echo "Patching app-config.yaml file to allow 'blob:' in content security policy.\n"
yq -i '.backend.csp.connect-src += ["blob: "]' app-config.yaml

# Doing this with sed, as I can't find the proper yq command to format this correctly ...
echo "Patching app-config yaml file to add content security policy script source configuration.\n"
sed <<EOF -i'.prepatch' -e '/connect-src/ a\
    script-src: ["'"'self'"'", '"'blob: '"', "'"'unsafe-eval'"'"]\
    img-src: ["'"'self'"'", '"'data:'"', '"'https://cdn.redoc.ly/redoc/logo-mini.svg'"']
' app-config.yaml
EOF
# Removing the backup file that is created.
rm app-config.yaml.prepatch

echo "Patching app-config.yaml file to add PostgreSQL configuration.\n"
yq -i '.backend += {"database": {"client": "pg", "connection": { "host": "${POSTGRES_SERVICE_HOST}", "port": "${POSTGRES_SERVICE_PORT}", "user": "${POSTGRES_USER}", "password": "${POSTGRES_PASSWORD}"}}}' app-config.yaml

############# Add Gloo Platform Portal Backstage plugin #############

echo #Adding Gloo Platform Portal Backstage plugin.\n"

yarn add --cwd packages/app @solo.io/dev-portal-backstage-plugin

pushd packages/app/src

echo "Add Gloo import statement to App.tsx backstage file.\n"
# Use sed to add import to App.tsx.
# The following command, using the "-i'{backup extension}'" syntax, is the only syntax that seems to work across macOS sed and GNU sed .... so don't try to fiddle with it, unless you test it on both macOS and Linux!!!
sed <<EOF -i'.orig' -e '1 i\
import {\
  GlooPortalHomePage,\
  GlooPortalApiDetailsPage,\
} from "@solo.io/dev-portal-backstage-plugin";
' App.tsx
EOF
# Removing the backup file that is created.
rm App.tsx.orig


echo "Add Gloo routes to <FlatRoutes> element in App.tsx backstage file.\n"
# Use sed to add element to <FlatRoutes> in App.tsx.
# The following command, using the "-i'{backup extension}'" syntax, is the only syntax that seems to work across macOS sed and GNU sed .... so don't try to fiddle with it, unless you test it on both macOS and Linux!!!
sed <<EOF -i'.orig' -e '/<\/FlatRoutes>/ i\
    <Route path="/gloo-platform-portal" element={<GlooPortalHomePage />} />\
    <Route path="/gloo-platform-portal/apis" element={<GlooPortalHomePage />} />\
    <Route path="/gloo-platform-portal/usage-plans" element={<GlooPortalHomePage />} />\
    <Route\
      path="/gloo-platform-portal/apis/:apiId"\
      element={<GlooPortalApiDetailsPage />}\
    />
' App.tsx 
EOF
# Removing the backup file that is created.
rm App.tsx.orig

popd
pushd packages/app/src/components/Root

echo "Add Gloo import statement to Root.tsx backstage file.\n"
# Use sed to add import to App.tsx.
# The following command, using the "-i'{backup extension}'" syntax, is the only syntax that seems to work across macOS sed and GNU sed .... so don't try to fiddle with it, unless you test it on both macOS and Linux!!!
sed <<EOF -i'.orig' -e '1 i\
import { GlooIcon } from "@solo.io/dev-portal-backstage-plugin";
' Root.tsx
EOF
# Removing the backup file that is created.
rm Root.tsx.orig

echo "Add Gloo routes to <SidebarScrollWrapper> element in Root.tsx backstage file.\n"
# Use sed to add element to <SidebarScrollWrapper> in Root.tsx.
# The following command, using the "-i'{backup extension}'" syntax, is the only syntax that seems to work across macOS sed and GNU sed .... so don't try to fiddle with it, unless you test it on both macOS and Linux!!!
sed <<EOF -i'.orig' -e '/<\/SidebarScrollWrapper>/ i\
          <SidebarItem icon={GlooIcon} to="gloo-platform-portal" text="Gloo Portal" />
' Root.tsx 
EOF
# Removing the backup file that is created.
rm Root.tsx.orig

popd

echo "Add Gloo Platform Portal plugin configuration options to Backstage app-config.yaml.\n"
#yq -i '. += {"glooPlatformPortal": {"portalServerUrl": "http://developer.example.com/portal-server/v1/", "clientId": "${CLIENT_ID}", "clientSecret": "${CLIENT_SECRET}", "tokenEndpoint": "http://keycloak.example.com:8080/realms/master/protocol/openid-connect/token", "authEndpoint": "http://keycloak.example.com:8080/realms/master/protocol/openid-connect/auth", "logoutEndpoint": "http://keycloak.example.com:8080/realms/master/protocol/openid-connect/logout"}} | .glooPlatformPortal.portalServerUrl style="double" | .glooPlatformPortal.tokenEndpoint style="double" | .glooPlatformPortal.authEndpoint style="double" | .glooPlatformPortal.logoutEndpoint style="double"' app-config.yaml
yq -i '. += {"glooPlatformPortal": {"portalServerUrl": "${PORTAL_SERVER_URL}", "clientId": "${CLIENT_ID}", "tokenEndpoint": "${TOKEN_ENDPOINT}", "authEndpoint": "${AUTH_ENDPOINT}", "logoutEndpoint": "${LOGOUT_ENDPOINT}"}} ' app-config.yaml

echo "Copy app-config.yaml configuration file to backend directory."
cp app-config.yaml packages/backend

pushd packages/backend

echo "Patch the Dockerfile."
sed  -i'.orig' -e 's/^CMD.*/#&\nCMD ["node", "packages\/backend", "--config", "app-config.yaml"]/g' Dockerfile
rm Dockerfile.orig

popd

echo "Setup the project with YARN.\n"
yarn install --frozen-lockfile

echo "Run the Typescript compiler.\n"
yarn tsc

echo "Build the Backstage application.\n"
yarn build:backend --config app-config.yaml

echo "Generate the Docker image.\n"
#yarn build-image --tag backstage:$DOCKER_IMAGE_TAG
# Not using yarn build-image, as we want to do a multi-arch build.

docker buildx build -f packages/backend/Dockerfile --platform linux/amd64,linux/arm64 --push -t duncandoyle/backstage-gloo -t duncandoyle/backstage-gloo:$DOCKER_IMAGE_TAG .

echo "Backstage Docker image created successfully with name 'backstage-gloo' and tag '$DOCKER_IMAGE_TAG'.\n"