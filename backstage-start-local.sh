#!/bin/sh

export PORTAL_SERVER_URL=http://developer.example.com/v1/
export CLIENT_ID=portal-client
export TOKEN_ENDPOINT=http://keycloak.example.com/realms/master/protocol/openid-connect/token
export AUTH_ENDPOINT=http://keycloak.example.com/realms/master/protocol/openid-connect/auth
export LOGOUT_ENDPOINT=http://keycloak.example.com/realms/master/protocol/openid-connect/logout
#export CLIENT_SECRET=0LfNaPzip1RImEeAh2LK396GG8P4PzW5
export SA_CLIENT_ID=portal-sa
export SA_CLIENT_SECRET=C8dS94I8VVGgh327vslYca1M0HNO2Exf
export GPP_PLUGIN_DEBUG_LOGGING=true
export LOG_LEVEL=debug

export KUBERNETES_API_SERVER_URL=https://127.0.0.1:49750
export KUBERNETES_SKIP_TLS_VERIFY=true
export KUBERNETES_SERVICE_ACCOUNT_TOKEN=eyJhbGciOiJSUzI1NiIsImtpZCI6IlB1eUg3XzZuS1ZXWlJ2Z2hNVkJDYy00OWVRZ0FhMm40cHM5d0dwM19sYnMifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJiYWNrc3RhZ2UiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlY3JldC5uYW1lIjoiYmFja3N0YWdlLWt1YmUtc2Etc2VjcmV0Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImJhY2tzdGFnZS1rdWJlLXNhIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQudWlkIjoiZDkyYmNlMmQtNTE1OC00MjRhLTkyNjQtYjM3YmQyYzU2NjdiIiwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50OmJhY2tzdGFnZTpiYWNrc3RhZ2Uta3ViZS1zYSJ9.dIeGi09k3fc_yDMWYKPBdI2MIh_cvCSFBgLAHTdQ4vuI6fYGUUaU7ewvet5FolTgzJRw5Hfx_8WWUCR8VL5r0HSJ9cMTmE7eE1fqthlXZbK-WmFEuCkVVl1Ob_Csy5nwBqWGCHt7aKr-Bj-Zf758uSMq95sZsPrkNPZ9ht4_cgNwFcP4AmhuImOBXBeZTZqohlUBYx_ReQX6M052HjEVpntzaQgwGNA0JuDSLVknc1JNbe7SlJyI89Z0udZmVYBv3C6eMpYHhYJdbzJuTEcQKBvo3tpm3Tj2FiYndCK1SrzGOq-6E_2s4GmR6gOkZ1C3scv_ehbx5N4Y9ao8JLw5fQ

pushd backstage

# TODO: Auto patch db config to use SQL Lite
# database:
#     client: better-sqlite3
#     connection: ':memory:'
yq -i '.backend += {"database": {"client": "better-sqlite3", "connection": "':memory:'"}}' app-config.yaml
yq -i 'del(.integrations.github.[0].token)' app-config.yaml

yarn dev

# Reset app-config.yaml
yq -i '.backend += {"database": {"client": "pg", "connection": { "host": "${POSTGRES_SERVICE_HOST}", "port": "${POSTGRES_SERVICE_PORT}", "user": "${POSTGRES_USER}", "password": "${POSTGRES_PASSWORD}"}}}' app-config.yaml
popd