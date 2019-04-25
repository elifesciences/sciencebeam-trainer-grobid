FROM openjdk:8-jdk-stretch

RUN apt-get update \
    && apt-get install --assume-yes --no-install-recommends \
    wget unzip libxml2 rename python2.7-minimal \
    && apt-get clean

# install gcloud to make it easier to access cloud storage
# gcloud sdk cli only works with Python 2 (in 2019)
RUN mkdir -p /usr/local/gcloud \
    && curl -q https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.tar.gz -o /tmp/google-cloud-sdk.tar.gz \
    && tar -C /usr/local/gcloud -xvf /tmp/google-cloud-sdk.tar.gz \
    && rm /tmp/google-cloud-sdk.tar.gz \
    && /usr/local/gcloud/google-cloud-sdk/install.sh

ENV PATH /usr/local/gcloud/google-cloud-sdk/bin:$PATH

ARG grobid_tag
RUN wget --output-document=/tmp/grobid.zip --quiet --show-progress --progress=bar:force:noscroll \
    https://github.com/kermitt2/grobid/archive/${grobid_tag}.zip \
    && mkdir -p /opt \
    && unzip /tmp/grobid.zip -d /opt \
    && rm /tmp/grobid.zip \
    && mv /opt/grobid-* /opt/grobid-source

WORKDIR /opt/grobid-source

RUN mkdir -p .gradle
VOLUME /opt/grobid-source/.gradle

RUN ./gradlew clean assemble --no-daemon

# move up
ENV GROBID_VERSION=${grobid_tag}

WORKDIR /opt/grobid

RUN cp -a \
    /opt/grobid-source/grobid-trainer/build/libs/grobid-trainer-${GROBID_VERSION}-onejar.jar \
    ./ \
    && ln -s grobid-trainer-${GROBID_VERSION}-onejar.jar grobid-trainer-onejar.jar \
    && cp -a \
    /opt/grobid-source/grobid-core/build/libs/grobid-core-${GROBID_VERSION}-onejar.jar \
    ./ \
    && ln -s grobid-core-${GROBID_VERSION}-onejar.jar grobid-core-onejar.jar

COPY scripts /opt/scripts
ENV PATH /opt/scripts:$PATH

ENV JAVA_OPTS -Xmx1G
