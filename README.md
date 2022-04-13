# Emulating Kubernetes volumeMount, emptyDir, and envFrom during local Docker dev lifecycle

When deploying a container to Kubernetes, you can mount files and secrets to specific locations in the filesystem, as well as populate environment variables from a file or key. For example, with NGINX container you can mount:

* /etc/nginx/nginx.conf - control the NGINX configuration
* /usr/share/nginx/html/index.html - the default content delivered
* /var/log/nginx - as an ephemeral directory for logs

or set environment variables:

* env.properties - use a file to set an entire list of key/value environment variables
* set a single key/value


But how do you emulate these when you are going through the software development lifecycle using a local Docker service?

## Docker file mounting using volume

You can mount local files to a specific location using the ['-v' volume](https://docs.docker.com/storage/volumes/) flag.  For example:

```
docker ... -v /my/local/path/nginx.conf:/etc/nginx/nginx.conf:ro
```

## Docker ephemeral directories using tempfs

You can create ephemeral directories using the [tmpfs mount](https://docs.docker.com/storage/tmpfs/). For example:

```
docker ... --mount type=tmpfs,destination=/var/log/nginx
```

We are using '--mount' instead of the '--tmpfs' flag for interoperability with OS other than Linux.

## Docker single environment variable

```
docker ... --env key=value
```

## Docker set environment variables from file

```
docker ... -env-file env.properties
```

