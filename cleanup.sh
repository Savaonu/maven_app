#!/bin/bash

container=$(docker ps -a --filter "name=my_maven_app" --format '{{.Names}}')

# Stop and delete containers
if [ -z "$container" ] ; then echo "No containers to delete"; else echo "The following container(s) will be deleted: "; docker stop $container && docker rm $container ; fi

# Delete old images
#images=$(docker image ls --filter label=type=maven_image  --format="{{.ID}}")
#if [ -z "$images" ]; then echo "No images to delete"; else echo "The following image(s) will be deleted: "; docker rmi $(docker image ls --filter label=type=maven_image  --format="{{.ID}}"); fi
