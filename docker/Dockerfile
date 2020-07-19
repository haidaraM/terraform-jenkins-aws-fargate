FROM jenkins/jenkins:lts-alpine

USER root

# Need awscli to get jenkins configuration from S3
RUN apk add --no-cache python3 && pip3 install awscli

USER jenkins

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

COPY ./master-entrypoint.sh /usr/bin/entrypoint

ENTRYPOINT ["/usr/bin/entrypoint"]
