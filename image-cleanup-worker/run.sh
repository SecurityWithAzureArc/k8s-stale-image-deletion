#!/bin/bash

if [ ! -e "/var/run/docker.sock" ]; then
    echo "Cannot find docker socket(/var/run/docker.sock), please check the command!"
    exit 1
fi

if docker version >/dev/null; then
    echo "docker is running properly"
else
    echo "Cannot run docker binary at /usr/bin/docker"
    echo "Please check if the docker binary is mounted correctly"
    exit 1
fi

echo "Start removing unused images"

# Get all image ID
ALL_LAYER_NUM=$(docker images -a | tail -n +2 | wc -l)
docker images -q --no-trunc | sort -o ImageIdList
CONTAINER_ID_LIST=$(docker ps -aq --no-trunc)
# Get Image ID that is used by a container
rm -f ContainerImageIdList
touch ContainerImageIdList
for CONTAINER_ID in ${CONTAINER_ID_LIST}; do
    LINE=$(docker inspect ${CONTAINER_ID} | grep "\"Image\": \"\(sha256:\)\?[0-9a-fA-F]\{64\}\"")
    IMAGE_ID=$(echo ${LINE} | awk -F '"' '{print $4}')
    echo "${IMAGE_ID}" >> ContainerImageIdList
done
sort ContainerImageIdList -o ContainerImageIdList

# we need to exempt k8s infra images, some of these are non-deletable and will cause failures
# Get exempt images
EXEMPT_REGISTRIES_LIST=$(cat ExemptRegistriesList)
# Get Image ID that originates from an exempt registry
rm -f ExemptImageIdList
touch ExemptImageIdList
for EXEMPT_REGISTRY in ${EXEMPT_REGISTRIES_LIST}; do
    EXEMPT_CONTAINER_ID_LIST=$(docker ps -a --no-trunc | grep ${EXEMPT_REGISTRY} | awk -F ' ' '{print $1}')
    for EXEMPT_CONTAINER_ID in ${EXEMPT_CONTAINER_ID_LIST}; do
        LINE=$(docker inspect ${EXEMPT_CONTAINER_ID} | grep "\"Image\": \"\(sha256:\)\?[0-9a-fA-F]\{64\}\"")
        IMAGE_ID=$(echo ${LINE} | awk -F '"' '{print $4}')
        echo "${IMAGE_ID}" >> ExemptImageIdList
    done
done
sort ExemptImageIdList -o ExemptImageIdList

# Remove the images being used by containers from the delete list
comm -23 ImageIdList ContainerImageIdList > ToBeCleaned
comm -23 ToBeCleaned ExemptImageIdList > ToBeCleanedAndNotExempt

# Remove Images
if [ -s ToBeCleanedAndNotExempt ]; then
    echo "Start to clean $(cat ToBeCleanedAndNotExempt | wc -l) images"
    docker rmi $(cat ToBeCleanedAndNotExempt)
    (( DIFF_IMG=$(cat ImageIdList | wc -l) - $(docker images | tail -n +2 | wc -l) ))
    if [ ! ${DIFF_IMG} -gt 0 ]; then
            DIFF_IMG=0
    fi
    echo "Done! ${DIFF_IMG} images have been cleaned."
else
    echo "No images need to be cleaned"
fi

rm -f ContainerImageIdList ExemptImageIdList ToBeCleaned ImageIdList ToBeCleanedAndNotExempt

echo "End of image cleanup"