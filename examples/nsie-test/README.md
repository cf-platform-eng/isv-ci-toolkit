# NSie test (install a single instance from a chart)

* Not on demand 
* No create-service
* Requires only PKS.

Used to establish the 'Test µplatform'


## Setup

* install bin dependencies (due to licensing issues)
    * download bazaar
        * copy it to `./tmp/bazaar`
    * download pks
        * copy it to `./tmp/pks`

* login to pks

```bash
export CLUSTER_NAME=<cluster_name>
pks login -a https://api.pks.whatever.com:9021 -u <username> -p <password> -k
```

* provide your tgz'ed helm chart
```bash
mkdir -p ./input/chart
cp your/chart/chart.tgz ./input/chart
``` 

## Debug process


Executing the shell target let's you interact directly with the test scripts.
Local editing works as the ./test dir is mapped 
```
make shell
$ . command.sh
```