#!/bin/sh

export PORTAL_SERVER_URL=http://developer.example.com/v1/
export CLIENT_ID=portal-client
export TOKEN_ENDPOINT=http://keycloak.example.com/realms/master/protocol/openid-connect/token
export AUTH_ENDPOINT=http://keycloak.example.com/realms/master/protocol/openid-connect/auth
export LOGOUT_ENDPOINT=http://keycloak.example.com/realms/master/protocol/openid-connect/logout
#export CLIENT_SECRET=0LfNaPzip1RImEeAh2LK396GG8P4PzW5
export SA_CLIENT_ID=portal-sa
export SA_CLIENT_SECRET=WowCYdKHpVKxhXG8IbeN0W70OnMsXFTV
export GPP_PLUGIN_DEBUG_LOGGING=true
export LOG_LEVEL=debug

export KUBERNETES_API_SERVER_URL=https://127.0.0.1:49828
export KUBERNETES_SKIP_TLS_VERIFY=true
export KUBERNETES_SERVICE_ACCOUNT_TOKEN=eyJhbGciOiJSUzI1NiIsImtpZCI6InZSMlhrTXIwVU9WRXpfZzJNdVR5UmY2WF9taTJlUlB6czJyWDZnWHVsRUkifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJkZWZhdWx0Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6ImRlZmF1bHQtc2VjcmV0Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImRlZmF1bHQiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiJmZDZjZWEwNy01N2NmLTQwZWYtYjNhYy1mODdhY2ZlZDRiOGYiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6ZGVmYXVsdDpkZWZhdWx0In0.hxdiuhTET_HZ7u9fTVChNGISKy7aBpAjyVB4OBp6UiA9svxn7snBModxXNiYy2EMAlOHZoTYh6u2ZtsnTU-tXrXRwctxiUd_T3ZldLrLzwNV5JP5IpPGBFlOzrO6krbWJSn6ONlKIJV2J3RQ5Fswy8DfL3xWSmSrjBKt_UsUfTcwbW5IH7ai-7VttlxTlZayR3NP_XMx8gW13XupPWjQy5zl-PLjuaEIiQid7WfjX3rM1SIvpIGbjtJk4tG3R3QYO44FI84g5KE5HvLNMHqb2huf_Sr9LoOnMsadU93xFHTUu5Pxj71QVebh96QOjoujw4_VvU4Mgn5ieVxatK_3-w

pushd backstage

# TODO: Auto patch db config to use SQL Lite
# database:
#     client: better-sqlite3
#     connection: ':memory:'
yq -i '.backend += {"database": {"client": "better-sqlite3", "connection": "':memory:'"}}' app-config.yaml

yarn dev

# Reset app-config.yaml
yq -i '.backend += {"database": {"client": "pg", "connection": { "host": "${POSTGRES_SERVICE_HOST}", "port": "${POSTGRES_SERVICE_PORT}", "user": "${POSTGRES_USER}", "password": "${POSTGRES_PASSWORD}"}}}' app-config.yaml
popd