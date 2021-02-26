# Enable Apps Manager errand

Running this task against a TAS foundation will enable Apps Manager.

## Inputs

You can either run this with environment variables, or with an environment file:

```bash
docker run --rm -v /path/to/environment.json:/input/environment.json enable-apps-manager
```

or

```bash
docker run --rm \
    --env OM_TARGET=https://pcf.vividlimegreen.cf-app.com \
    --env OM_USERNAME=pivotalcf \
    --env OM_PASSWORD=supersecretpassword \
    enable-apps-manager
```
