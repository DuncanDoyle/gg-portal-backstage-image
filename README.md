# Gloo Platform Portal Backstage image

This repository provides a script to generate a Backstage container image with the [Gloo Platform Portal Backstage plugin](https://github.com/solo-io/dev-portal-backstage-public#readme) plugin pre-installed.

Use the following command to generate the Docker image. Provide the _tag_ that you want your image to be tagged with as a parameter to the script

```
./build-backstage-image-with-gloo-platform-portal.sh 1.16
```

The container image requires the following variables to be set:

| Environment Variable | Description                                          |
| -------------------- | ---------------------------------------------------- |
| PORTAL_SERVER_URL    | The URL of the Gloo Platform Portal REST server.     |
| TOKEN_ENDPOINT       | This is the endpoint to get the oauth token.         |
| AUTH_ENDPOINT        | This is the endpoint to get PKCE authorization code. |
| LOGOUT_ENDPOINT      | This is the endpoint to end your session.            |
| CLIENT_ID            | The oauth client id.                                 |