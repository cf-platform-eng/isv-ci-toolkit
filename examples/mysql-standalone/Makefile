SHELL = /bin/bash
default: build

build:
	docker build . -t cfplatformeng/test-mysql-standalone

publish:
	echo "PKS licensing is blocking this"
#	docker push cfplatformeng/test-mysql-standalone

run:
	docker run -it cfplatformeng/test-mysql-standalone:latest /bin/bash