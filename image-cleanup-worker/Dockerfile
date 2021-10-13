FROM alpine:latest

# run.sh script uses some bash specific syntax
RUN apk add --update bash docker grep dos2unix curl wget

ARG VERSION="v1.22.0"
RUN curl -L https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-${VERSION}-linux-amd64.tar.gz --output crictl-${VERSION}-linux-amd64.tar.gz
RUN tar zxvf crictl-$VERSION-linux-amd64.tar.gz -C /usr/local/bin
RUN rm -f crictl-$VERSION-linux-amd64.tar.gz

#install yq
RUN wget https://github.com/mikefarah/yq/releases/download/v4.13.4/yq_linux_amd64
RUN mv ./yq_linux_amd64 /usr/local/bin/yq
RUN chmod +x /usr/local/bin/yq

# Install cleanup script
RUN mkdir /job
ADD run.sh /job/run.sh
RUN dos2unix /job/run.sh
ADD wrapper.sh /job/wrapper.sh
RUN dos2unix /job/wrapper.sh
ADD ExemptRegistriesList /job/ExemptRegistriesList

WORKDIR /job

CMD ["/bin/bash", "./wrapper.sh"]