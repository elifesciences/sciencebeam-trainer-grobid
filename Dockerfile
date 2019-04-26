ARG builder_image
FROM ${builder_image} AS builder

FROM openjdk:8-jre-stretch

RUN apt-get update \
    && apt-get install --assume-yes --no-install-recommends \
    wget unzip libxml2 rename python2.7-minimal libpython2.7-stdlib \
    && rm -rf /var/lib/apt/lists/*

# install gcloud to make it easier to access cloud storage
# gcloud sdk cli only works with Python 2 (in 2019)
RUN mkdir -p /usr/local/gcloud \
    && curl -q https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.tar.gz -o /tmp/google-cloud-sdk.tar.gz \
    && tar -C /usr/local/gcloud -xvf /tmp/google-cloud-sdk.tar.gz \
    && rm /tmp/google-cloud-sdk.tar.gz \
    && /usr/local/gcloud/google-cloud-sdk/install.sh

ENV PATH /usr/local/gcloud/google-cloud-sdk/bin:$PATH

WORKDIR /opt/grobid
COPY --from=builder /opt/grobid/* ./
COPY --from=builder /opt/grobid-source/grobid-home /opt/grobid-source/grobid-home
COPY --from=builder /opt/grobid-source/grobid-trainer/resources /opt/grobid-source/grobid-trainer/resources

COPY scripts /opt/scripts
ENV PATH /opt/scripts:$PATH

ENV JAVA_OPTS=-Xmx1G

ARG grobid_tag
ENV GROBID_VERSION=${grobid_tag}
LABEL org.elifesciences.dependencies.grobid="${grobid_tag}"

ARG image_tag
LABEL org.opencontainers.image.revision="${image_tag}"