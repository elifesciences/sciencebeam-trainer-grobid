FROM openjdk:8u212-jdk-stretch AS builder

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

RUN ./gradlew -Pversion=${grobid_tag} clean assemble --no-daemon

WORKDIR /opt/grobid

RUN cp -a \
    /opt/grobid-source/grobid-trainer/build/libs/grobid-trainer-${grobid_tag}-onejar.jar \
    ./ \
    && ln -s grobid-trainer-${grobid_tag}-onejar.jar grobid-trainer-onejar.jar \
    && cp -a \
    /opt/grobid-source/grobid-core/build/libs/grobid-core-${grobid_tag}-onejar.jar \
    ./ \
    && ln -s grobid-core-${grobid_tag}-onejar.jar grobid-core-onejar.jar
