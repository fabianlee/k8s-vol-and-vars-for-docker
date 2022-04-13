OWNER := fabianlee
PROJECT := k8s-vol-and-vars-for-docker
VERSION := 1.0.0
OPV := $(OWNER)/$(PROJECT):$(VERSION)
EXPOSEDPORT := 8080
SINGLE_ENV := --env my_key="My value"
FILE_ENV := --env-file k8s/nginx-basic-auth/env.properties

# https://docs.docker.com/storage/volumes/ 
# https://docs.docker.com/storage/tmpfs/ (only for linux '--tmpfs /var/log/nginx')
# mount nginx.conf,index.html,.htpaswd, ephemeral log dir
VOL_FLAG= -v $(shell pwd)/k8s/nginx-basic-auth/nginx.conf:/etc/nginx/nginx.conf:ro -v $(shell pwd)/k8s/nginx-basic-auth/cm-index.html:/usr/share/nginx/html/index.html:ro -v $(shell pwd)/k8s/nginx-basic-auth/htpasswd:/usr/share/nginx/html/.htpasswd:ro --mount type=tmpfs,destination=/var/log/nginx

# you may need to change to "sudo docker" if not a member of 'docker' group
# add user to docker group: sudo usermod -aG docker $USER
DOCKERCMD := "docker"

BUILD_TIME := $(shell date -u '+%Y-%m-%d_%H:%M:%S')
# unique id from last git commit
MY_GITREF := $(shell git rev-parse --short HEAD)


## builds docker image
docker-build:
	@echo MY_GITREF is $(MY_GITREF)
	$(DOCKERCMD) build -f Dockerfile -t $(OPV) .

## cleans docker image
clean:
	$(DOCKERCMD) image rm $(OPV) | true

## runs container in foreground
docker-run-fg: docker-port-clear
	$(DOCKERCMD) run -it -p $(EXPOSEDPORT):80 $(VOL_FLAG) $(SINGLE_ENV) $(FILE_ENV) --rm $(OPV)

## runs container in foreground, override entrypoint to use use shell
docker-debug:
	$(DOCKERCMD) run -it --rm $(VOL_FLAG) $(SINGLE_ENV) $(FILE_ENV) --entrypoint "/bin/sh" $(OPV)

## run container in background
docker-run-bg: docker-port-clear
	$(DOCKERCMD) run -d -p $(EXPOSEDPORT):80 $(VOL_FLAG) $(SINGLE_ENV) $(FILE_ENV) --rm --name $(PROJECT) $(OPV)

docker-port-clear:
	! sudo netstat -tulnp | grep LISTEN | grep ':$(EXPOSEDPORT)' || { echo -e "\n!!! ERROR port $(EXPOSEDPORT) already bound locally"; exit 3; }

## get into console of container running in background
docker-cli-bg:
	$(DOCKERCMD) exec -it $(PROJECT) /bin/sh

## tails $(DOCKERCMD)logs
docker-logs:
	$(DOCKERCMD) logs -f $(PROJECT)

## stops container running in background
docker-stop:
	$(DOCKERCMD) stop $(PROJECT)

## runs curl test against running container
test:
	@echo ""
	@echo "Test of public content"
	curl http://localhost:$(EXPOSEDPORT)
	@echo ""
	@echo "Test of restricted content"
	curl -u "myuser:MyF4kePassw@rd" http://localhost:$(EXPOSEDPORT)/restricted/
	@echo ""
	@echo "Check environmental variables"
	$(DOCKERCMD) exec -it $(PROJECT) /bin/sh -c "env | sort | grep ^[a-z]"

## pushes to $(DOCKERCMD)hub
docker-push:
	$(DOCKERCMD) push $(OPV)

## pushes to kubernetes cluster
k8s-apply:
	cd k8s/nginx-basic-auth && kubectl kustomize
	cd k8s/nginx-basic-auth && kubectl apply -k .

## deletes from k8s cluster
k8s-delete:
	cd k8s/nginx-basic-auth && kubectl delete -k .

## test inside k8s cluster
k8s-test:
	cd k8s/nginx-basic-auth && ./test.sh
