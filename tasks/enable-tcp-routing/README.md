# Enable TCP Routing

Running this task against a PCF foundation will enable TCP Routing.

## Inputs

This task requires the om tool to be properly configured, so these environment variables are required:

- OM_TARGET - url for opsman (ex: `https://pcf.vividlimegreen.cf-app.com`)
- OM_USERNAME - opsman username
- OM_PASSWORD - opsman password

Also required is the environment.json file, volume mounted to `test-input-files`
