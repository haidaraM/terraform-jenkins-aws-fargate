FROM jenkins/jenkins:2.338

USER root

# Need awscli to get jenkins configuration from S3
RUN apt update && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && ./aws/install && rm -rf awscliv2.zip ./aws && aws --version

USER jenkins

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

COPY ./controller-entrypoint.sh /usr/bin/entrypoint

ENTRYPOINT ["/usr/bin/entrypoint"]
