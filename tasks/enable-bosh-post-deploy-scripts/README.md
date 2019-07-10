# Enable BOSH post-deploy errands

Running this task against a PCF foundation will enable BOSH post-deploy errands.

## Inputs

This task requires the om tool to be properly configured, so these environment variables are required:

- OM_TARGET - url for opsman (ex: `https://pcf.vividlimegreen.cf-app.com`)
- OM_USERNAME - opsman username
- OM_PASSWORD - opsman password
