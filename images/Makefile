build-om: Dockerfile.om
	docker build --build-arg OM_CLI_VER=${OM_CLI_VER} --tag cfplatformeng/om:dev --file Dockerfile.om .

build-pivnet: Dockerfile.pivnet
	docker build --build-arg PIVNET_CLI_VER=${PIVNET_CLI_VER} --tag cfplatformeng/pivnet:dev --file Dockerfile.pivnet .
