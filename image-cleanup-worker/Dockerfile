FROM alpine:latest

# run.sh script uses some bash specific syntax
RUN apk add --update bash docker grep dos2unix

# Install cleanup script
ADD run.sh /run.sh
RUN dos2unix /run.sh
ADD wrapper.sh /wrapper.sh
RUN dos2unix /wrapper.sh
ADD ExemptRegistriesList /ExemptRegistriesList

CMD ["/bin/bash", "/wrapper.sh"]