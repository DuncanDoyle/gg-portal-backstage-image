#!/bin/sh
echo "Building Backstage platform with Gloo Platform Portal plugins.\n"

echo "Source nvm.sh to make nvm available to our script.\n"
. ~/.nvm/nvm.sh

echo "Set NVM version.\n"

# yarn set version 1.22.19
nvm use 18
# nvm use 16

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

############# Add Gloo Platform Portal Backstage Plugin Fontend #############

echo "Adding Gloo Platform Portal Backstage Plugin Frontend.\n"

yarn add --cwd packages/app @solo.io/platform-portal-backstage-plugin-frontend

pushd packages/app/src

echo "Add Gloo import statement to App.tsx backstage file.\n"
# Use sed to add import to App.tsx.
# The following command, using the "-i'{backup extension}'" syntax, is the only syntax that seems to work across macOS sed and GNU sed .... so don't try to fiddle with it, unless you test it on both macOS and Linux!!!
sed <<EOF -i'.orig' -e '1 i\
import {\
  GlooPortalHomePage,\
  GlooPortalApiDetailsPage,\
} from "@solo.io/platform-portal-backstage-plugin-frontend";
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
import { GlooIcon } from "@solo.io/platform-portal-backstage-plugin-frontend";
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

echo "Add Gloo Platform Portal plugin configuration options for frontend plugin to Backstage app-config.yaml.\n"
#yq -i '. += {"glooPlatformPortal": {"portalServerUrl": "http://developer.example.com/portal-server/v1/", "clientId": "${CLIENT_ID}", "clientSecret": "${CLIENT_SECRET}", "tokenEndpoint": "http://keycloak.example.com:8080/realms/master/protocol/openid-connect/token", "authEndpoint": "http://keycloak.example.com:8080/realms/master/protocol/openid-connect/auth", "logoutEndpoint": "http://keycloak.example.com:8080/realms/master/protocol/openid-connect/logout"}} | .glooPlatformPortal.portalServerUrl style="double" | .glooPlatformPortal.tokenEndpoint style="double" | .glooPlatformPortal.authEndpoint style="double" | .glooPlatformPortal.logoutEndpoint style="double"' app-config.yaml
yq -i '. += {"glooPlatformPortal": {"portalServerUrl": "${PORTAL_SERVER_URL}", "clientId": "${CLIENT_ID}", "tokenEndpoint": "${TOKEN_ENDPOINT}", "authEndpoint": "${AUTH_ENDPOINT}", "logoutEndpoint": "${LOGOUT_ENDPOINT}"}} ' app-config.yaml

echo "Copy app-config.yaml configuration file to backend directory."
cp app-config.yaml packages/backend

############# Add Gloo Platform Portal Backstage Plugin Backend #############

echo "Adding Gloo Platform Portal Backstage Plugin Backend.\n"

yarn add --cwd packages/backend @solo.io/platform-portal-backstage-plugin-backend

pushd packages/backend/src/plugins

# Use sed to add import to catalog.ts.
# The following command, using the "-i'{backup extension}'" syntax, is the only syntax that seems to work across macOS sed and GNU sed .... so don't try to fiddle with it, unless you test it on both macOS and Linux!!!
sed <<EOF -i'.orig' -e '1 i\
import { GlooPlatformPortalProvider } from "@solo.io/platform-portal-backstage-plugin-backend";
' catalog.ts
EOF
# Removing the backup file that is created.
rm catalog.ts.orig

# Use sed to add gloo platform portal provider to catalog.ts
# The following command, using the "-i'{backup extension}'" syntax, is the only syntax that seems to work across macOS sed and GNU sed .... so don't try to fiddle with it, unless you test it on both macOS and Linux!!!
sed <<EOF -i'.orig' -e '/const builder/ a\
\
  const gppp = new GlooPlatformPortalProvider(\
    '\''production'\'',\
    env.logger,\
    env.config,\
  );\
  builder.addEntityProvider(gppp);\
' catalog.ts
EOF
# Removing the backup file that is created.
rm catalog.ts.orig

# Use sed to add gloo platform portal provider to catalog.ts
# The following command, using the "-i'{backup extension}'" syntax, is the only syntax that seems to work across macOS sed and GNU sed .... so don't try to fiddle with it, unless you test it on both macOS and Linux!!!
sed <<EOF -i'.orig' -e '/await processingEngine\.start/ a\
\
  await gppp.startScheduler(env.scheduler);\
' catalog.ts
EOF
# Removing the backup file that is created.
rm catalog.ts.orig

popd

echo "Add Gloo Platform Portal plugin configuration options for backend plugin to Backstage app-config.yaml.\n"
yq -i '.glooPlatformPortal += {"backend": {"portalServerUrl": "${PORTAL_SERVER_URL}", "clientId": "${SA_CLIENT_ID}", "clientSecret": "${SA_CLIENT_SECRET}", "tokenEndpoint": "${TOKEN_ENDPOINT}", "debugLogging": "${GPP_PLUGIN_DEBUG_LOGGING}", "syncFrequency": { "hours": 0, "minutes": 1, "seconds": 0, "milliseconds": 0}, "syncTimeout": { "hours": 0, "minutes": 0, "seconds": 10, "milliseconds": 0}}}' app-config.yaml

echo "Copy app-config.yaml configuration file to backend directory."
cp app-config.yaml packages/backend

############# Add Kubernetes Frontend Backstage Plugin #############

echo "Adding Kubernetes Frontend Backstage Plugin.\n"

yarn add --cwd packages/app @backstage/plugin-kubernetes

pushd packages/app/src/components/catalog

# Use sed to add import to EntityPage.tsx
# The following command, using the "-i'{backup extension}'" syntax, is the only syntax that seems to work across macOS sed and GNU sed .... so don't try to fiddle with it, unless you test it on both macOS and Linux!!!
sed <<EOF -i'.orig' -e '1 i\
import { EntityKubernetesContent } from '\''@backstage/plugin-kubernetes'\'';
' EntityPage.tsx
EOF
# Removing the backup file that is created.
rm EntityPage.tsx.orig

# Add Kubernetes tab to catalog pages. (see https://unix.stackexchange.com/questions/483150/adding-text-to-a-file-2-lines-before-the-last-pattern-match for matching approach)
# Note: I've not found a way with sed to start matching a pattern starting at a given line-number, and appending text before that match. That's the reason for doing a "grep" twice.
# There is a probably a way to do this in POSIX sed, so feel free to replace with a proper set expression.

# Find the linenumber of the serviceEntityPage section
line=$(grep -n 'const serviceEntityPage' EntityPage.tsx | tail -n1 | cut -f1 -d:)
# From that point, find the closing </EntityLayout> tag of that section
line2=$(tail -n +$line EntityPage.tsx | grep -n '</EntityLayout>' | head -n1 | cut -f1 -d:)
# Calculate the line number of that </EntityLayout> tag
targetLine=$(($line + $line2 ))
((--targetLine))
# Insert the config before that linenumber.
sed <<EOF -i'.orig' "${targetLine} i\\
    <EntityLayout.Route path=\"/kubernetes\" title=\"Kubernetes\">\\
      <EntityKubernetesContent refreshIntervalMs={30000} />\\
    </EntityLayout.Route>
" EntityPage.tsx
EOF

# Removing the backup file that is created.
rm EntityPage.tsx.orig

popd

############# Add Kubernetes Backend Backstage Plugin #############

echo "Adding Kubernetes Backend Backstage Plugin.\n"

yarn add --cwd packages/backend @backstage/plugin-kubernetes-backend

pushd packages/backend/src/plugins

cat <<EOF >> kubernetes.ts 
import { KubernetesBuilder } from '@backstage/plugin-kubernetes-backend';
import { Router } from 'express';
import { PluginEnvironment } from '../types';
import { CatalogClient } from '@backstage/catalog-client';

export default async function createPlugin(
  env: PluginEnvironment,
): Promise<Router> {
  const catalogApi = new CatalogClient({ discoveryApi: env.discovery });
  const { router } = await KubernetesBuilder.createBuilder({
    logger: env.logger,
    config: env.config,
    catalogApi,
    permissions: env.permissions,
  }).build();
  return router;
}
EOF

popd

pushd packages/backend/src
# Use sed to add import to index.ts
# The following command, using the "-i'{backup extension}'" syntax, is the only syntax that seems to work across macOS sed and GNU sed .... so don't try to fiddle with it, unless you test it on both macOS and Linux!!!
sed <<EOF -i'.orig' -e '/import search/ a\
import kubernetes from '\''./plugins/kubernetes'\'';
' index.ts
EOF
# Removing the backup file that is created.
rm index.ts.orig

sed <<EOF -i'.orig' -e '/const appEnv/ a\
  const kubernetesEnv = useHotMemoize(module, () => createEnv('\''kubernetes'\''));
' index.ts
EOF
# Removing the backup file that is created.
rm index.ts.orig

sed <<EOF -i'.orig' -e '/const apiRouter/ a\
  apiRouter.use('\''/kubernetes'\'', await kubernetes(kubernetesEnv));
' index.ts
EOF
# Removing the backup file that is created.
rm index.ts.orig

popd

### Configure the Kubernetes plugin.
yq -i '. += 
  {
    "kubernetes": {
      "serviceLocatorMethod": {
        "type": "multiTenant"
      },
      "clusterLocatorMethods": [
        {
          "type": "config",
          "clusters": [
            {
              "url": "${KUBERNETES_API_SERVER_URL}",
              "name": "kubernetes",
              "authProvider": "serviceAccount",
              "skipTLSVerify": "${KUBERNETES_SKIP_TLS_VERIFY}",
              "skipMetricsLookup": "true",
              "serviceAccountToken": "${KUBERNETES_SERVICE_ACCOUNT_TOKEN}",
              "customResources": [
                {
                  "group": "networking.gloo.solo.io",
                  "apiVersion": "v2",
                  "plural": "routetables"
                }
              ]
            }
          ]
        }
      ]
    }
  }' app-config.yaml

echo "Copy app-config.yaml configuration file to backend directory."
cp app-config.yaml packages/backend

############# Build container image #############

pushd packages/backend

echo "Patch the Dockerfile."
# Move to Node18
sed  -i'.orig' -e 's/^FROM.*/#&\nFROM node:18-bullseye-slim/g' Dockerfile
sed  -i'.orig' -e 's/^CMD.*/#&\nCMD ["node", "packages\/backend", "--config", "app-config.yaml"]/g' Dockerfile
rm Dockerfile.orig

popd

echo "Setup the project with YARN.\n"
yarn install --frozen-lockfile

echo "Run the Typescript compiler.\n"
yarn tsc

echo "Build the Backstage application.\n"
yarn build:backend --config app-config.yaml

echo "Backstage build complete.\n"
echo "To generate a Docker image for this build, run: './build-backstage-docker-image.sh {VERSION_TAG}'\n"