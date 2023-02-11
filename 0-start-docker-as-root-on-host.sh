# pull latest image again as sometimes this needs a retry, if it is there it will be fast
docker pull container-registry.oracle.com/database/express:latest

# docker run
docker_image_id=`docker images|tail -1|awk '{print $3}'`
echo $docker_image_id
docker run -it $docker_image_id /bin/bash

