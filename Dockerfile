ARG builder_image
FROM ${builder_image} AS builder

FROM openjdk:8u212-jre-slim

RUN apt-get update \
    && apt-get install --assume-yes --no-install-recommends \
    wget curl unzip libxml2 rename gcc g++ \
    python3-minimal python3-venv libpython3-stdlib python3-dev \
    && rm -rf /var/lib/apt/lists/*

# install gcloud to make it easier to access cloud storage
RUN mkdir -p /usr/local/gcloud \
    && curl -q https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.tar.gz -o /tmp/google-cloud-sdk.tar.gz \
    && tar -C /usr/local/gcloud -xvf /tmp/google-cloud-sdk.tar.gz \
    && rm /tmp/google-cloud-sdk.tar.gz \
    && /usr/local/gcloud/google-cloud-sdk/install.sh --usage-reporting false

ENV PATH /usr/local/gcloud/google-cloud-sdk/bin:$PATH

WORKDIR /opt/grobid
COPY --from=builder /opt/grobid/* ./
COPY --from=builder /opt/grobid-source/grobid-home /opt/grobid-source/grobid-home
COPY --from=builder /opt/grobid-source/grobid-trainer/resources /opt/grobid-source/grobid-trainer/resources

ENV PROJECT_FOLDER=/opt/sciencebeam-trainer-grobid

# create virtual env (see also https://bugs.python.org/issue24875)
ENV VENV=/opt/venv
COPY requirements.build.txt ${PROJECT_FOLDER}/
RUN python3 -m venv ${VENV} \
    && python3 -m venv ${VENV} \
    && ln -s ${VENV}/lib/python3.* ${VENV}/lib/python3 \
    && ${VENV}/bin/pip install -r ${PROJECT_FOLDER}/requirements.build.txt
ENV VIRTUAL_ENV=${VENV} PYTHONUSERBASE=${VENV} PATH=${VENV}/bin:$PATH

# install sciencebeam-trainer-grobid dependencies
COPY requirements.txt ${PROJECT_FOLDER}/
RUN pip install -r ${PROJECT_FOLDER}/requirements.txt

ARG install_dev
COPY requirements.dev.txt ./
RUN if [ "${install_dev}" = "y" ]; then pip install -r requirements.dev.txt; fi

# add sciencebeam_trainer_grobid package itself
COPY sciencebeam_trainer_grobid ${PROJECT_FOLDER}/sciencebeam_trainer_grobid

# install into venv
COPY setup.py README.md ${PROJECT_FOLDER}/
RUN pip install -e ${PROJECT_FOLDER} --no-deps

COPY scripts /opt/scripts
ENV PATH /opt/scripts:$PATH

# add additional wrapper entrypoint for OVERRIDE_MODELS
COPY ./docker/entrypoint.sh ${PROJECT_FOLDER}/entrypoint.sh
ENTRYPOINT ["/opt/sciencebeam-trainer-grobid/entrypoint.sh"]

RUN mkdir -p /data \
  chmod a+rw /data
VOLUME ["/data"]

ENV JAVA_OPTS=-Xmx1G

ARG grobid_tag
ENV GROBID_VERSION=${grobid_tag}
LABEL org.elifesciences.dependencies.grobid="${grobid_tag}"

ARG revision
LABEL org.opencontainers.image.revision="${revision}"
LABEL org.opencontainers.image.source=https://github.com/elifesciences/sciencebeam-trainer-grobid
