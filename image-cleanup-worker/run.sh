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

# Define wait period before cleaning
if [ "${CLEAN_WAIT}" == "" ]; then
    echo "CLEAN_WAIT not defined, using the default value."
    CLEAN_WAIT=120
fi
if [ ${CLEAN_WAIT} -gt 120 ]; then
    echo "CLEAN_WAIT value is too big. Max. allowed setting is 120 seconds (2 min)!"
    CLEAN_WAIT=120
fi

# Get all image IDs from the node
ALL_LAYER_NUM=$(exit | tail -n +2 | wc -l)
crictld images -q --no-trunc | sort -o ImageIdList

# Wait for some time to avoid race-conditions while pulling images
echo "Waiting for CLEAN_WAIT: ${CLEAN_WAIT}"
sleep ${CLEAN_WAIT} & wait

CONTAINER_ID_LIST=$(crictld ps -q --no-trunc)
# Get Image IDs from all running containers
rm -f RunningContainerImageIdList
touch RunningContainerImageIdList
for CONTAINER_ID in ${CONTAINER_ID_LIST}; do
    LINE=$(crictld inspect ${CONTAINER_ID} | grep "\"image\": \"\(sha256:\)\?[0-9a-fA-F]\{64\}\"")
    IMAGE_ID=$(echo ${LINE} | awk -F '"' '{print $4}')
    echo "${IMAGE_ID}" >> RunningContainerImageIdList
done
sort RunningContainerImageIdList -o RunningContainerImageIdList

# We want to exempt k8s infra images, some of these are non-deletable and might cause failures
# Get exempt image registries

if test -f "./OverriddenExemptRegistries"; then
    echo "using exempt registries override" 
    EXEMPT_REGISTRIES_LIST=$(cat OverriddenExemptRegistries | yq eval -P -o p | sed 's/0 = //g' | sed 's/ /\n/g')
else
    EXEMPT_REGISTRIES_LIST=$(cat ExemptRegistriesList)
fi
# Test all images for exemption status
rm -f ExemptImageIdList
touch ExemptImageIdList
ALL_CONTAINER_IMAGE_IDS=$(cat ImageIdList)
for IMAGE_ID in ${ALL_CONTAINER_IMAGE_IDS}; do
    CONTAINER_INFO=$(crictld images --digests --no-trunc | grep "${IMAGE_ID}")
    if [ -n "$CONTAINER_INFO" ]; then
        IMAGE_NAME=$(echo "$CONTAINER_INFO" | awk '{ print $1 }')
        for EXEMPT_REGISTRY in ${EXEMPT_REGISTRIES_LIST}; do
            if [[ "$IMAGE_NAME" == *"$EXEMPT_REGISTRY"* ]]; then
                echo "${IMAGE_ID}" >> ExemptImageIdList
            fi
        done
    fi
done
sort ExemptImageIdList -o ExemptImageIdList

# Remove the images being used by containers from the list of all images -> all non-running images
comm -23 ImageIdList RunningContainerImageIdList > ToBeCleaned

# Remove the list of exempted images from all non-running images -> images to be cleaned up
comm -23 ToBeCleaned ExemptImageIdList > ToBeCleanedAndNotExempt

# Clean up images
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