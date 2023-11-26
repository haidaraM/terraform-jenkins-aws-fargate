FROM --platform=linux/amd64 golang:1.20-bullseye as builder

# Version of soci-snapshotter to build
ARG SOCI_SNAPSHOTTER_VERSION=21ec5445ea5e0908861e60e92cbdcd70d3251c93
# Install required dependencies to build: https://github.com/awslabs/soci-snapshotter/blob/main/docs/build.md
RUN apt update && apt install -y zlib1g-dev

# Install
RUN git clone https://github.com/awslabs/soci-snapshotter && cd soci-snapshotter && \
    git checkout $SOCI_SNAPSHOTTER_VERSION && make

FROM --platform=linux/amd64 public.ecr.aws/amazonlinux/amazonlinux:2

RUN yum install -y unzip

# Replace with the relevant architecture
ENV ARCH=x86_64
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-$ARCH.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install

COPY --from=builder /go/soci-snapshotter/out/soci /usr/local/bin/soci

COPY --from=public.ecr.aws/docker/library/docker:latest /usr/local/bin/ctr /usr/local/bin/ctr
COPY --from=public.ecr.aws/docker/library/docker:latest /usr/local/bin/containerd /usr/local/bin/containerd
COPY --from=public.ecr.aws/docker/library/docker:latest /usr/local/bin/runc /usr/local/bin/runc

WORKDIR /
COPY script.sh /script.sh
ENTRYPOINT ["./script.sh"]
