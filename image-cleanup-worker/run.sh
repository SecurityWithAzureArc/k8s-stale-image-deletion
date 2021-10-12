#!/bin/bash
function crictld() {
    crictl -r unix:///var/run/containerd/containerd.sock "$@"
}

if [ ! -e "/var/run/containerd/containerd.sock" ]; then
    echo "Cannot find containerd socket(/var/run/containerd/containerd.sock), please check availability!"
    exit 1
fi

if crictld version >/dev/null; then
    echo "crictl is running properly"
else
    echo "Cannot run crictl binary at /usr/local/bin/crictl"
    echo "Please check if the crictl binary is mounted correctly"
    exit 1
fi

echo "Start removing unused images"

# Get all image ID
ALL_LAYER_NUM=$(crictld images | tail -n +2 | wc -l)
crictld images -q --no-trunc | sort -o ImageIdList
CONTAINER_ID_LIST=$(crictld ps -aq --no-trunc)
# Get Image ID that is used by a container
rm -f ContainerImageIdList
touch ContainerImageIdList
for CONTAINER_ID in ${CONTAINER_ID_LIST}; do
    LINE=$(crictld inspect ${CONTAINER_ID} | grep "\"Image\": \"\(sha256:\)\?[0-9a-fA-F]\{64\}\"")
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
    EXEMPT_CONTAINER_ID_LIST=$(crictld ps -a --no-trunc | grep ${EXEMPT_REGISTRY} | awk -F ' ' '{print $1}')
    for EXEMPT_CONTAINER_ID in ${EXEMPT_CONTAINER_ID_LIST}; do
        LINE=$(crictld inspect ${EXEMPT_CONTAINER_ID} | grep "\"image\": \"\(sha256:\)\?[0-9a-fA-F]\{64\}\"")
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
    crictld rmi $(cat ToBeCleanedAndNotExempt)
    (( DIFF_IMG=$(cat ImageIdList | wc -l) - $(crictld images | tail -n +2 | wc -l) ))
    if [ ! ${DIFF_IMG} -gt 0 ]; then
            DIFF_IMG=0
    fi
    echo "Done! ${DIFF_IMG} images have been cleaned."
else
    echo "No images need to be cleaned"
fi

rm -f ContainerImageIdList ExemptImageIdList ToBeCleaned ImageIdList ToBeCleanedAndNotExempt

echo "End of image cleanup"