DOCKER_COMPOSE_DEV = docker-compose
DOCKER_COMPOSE_CI = docker-compose -f docker-compose.yml
DOCKER_COMPOSE = $(DOCKER_COMPOSE_DEV)

RUN = $(DOCKER_COMPOSE) run --rm sciencebeam-trainer-grobid

PDF_DATA_DIR = /data/pdf
DATASET_DIR = /data/dataset
XML_DATA_DIR = $(DATASET_DIR)/xml

TRAIN_ARGS =

USER_AGENT = Dummy/user-agent
SAMPLE_PDF_URL = https://cdn.elifesciences.org/articles/32671/elife-32671-v2.pdf

# Specify the location where to copy the model to
CLOUD_MODELS_PATH =


build:
	$(DOCKER_COMPOSE) build


example-data-processing-end-to-end: \
	get-example-data \
	generate-grobid-training-data \
	copy-raw-header-training-data-to-tei \
	train-header-model-with-dataset


get-example-data: build
	$(RUN) bash -c '\
		mkdir -p "$(PDF_DATA_DIR)" \
		&& curl --fail --show-error --connect-timeout 60 --user-agent "$(USER_AGENT)" --location \
			"$(SAMPLE_PDF_URL)" --silent -o "$(PDF_DATA_DIR)/sample.pdf" \
		&& ls -l "$(PDF_DATA_DIR)" \
		'


generate-grobid-training-data: build
	$(RUN) generate-grobid-training-data.sh \
		"${PDF_DATA_DIR}" \
    "$(DATASET_DIR)"


copy-raw-header-training-data-to-tei: build
	$(RUN) bash -c '\
		mkdir -p "$(DATASET_DIR)/header/corpus/tei" && \
		cp "$(DATASET_DIR)/header/corpus/tei-raw/"*.xml "$(DATASET_DIR)/header/corpus/tei/" \
		'


train-header-model-with-dataset: build
	$(RUN) train-header-model.sh \
		--dataset "$(DATASET_DIR)" \
		$(TRAIN_ARGS)


train-header-model-with-default-dataset: build
	$(RUN) train-header-model.sh \
		--use-default-dataset \
		$(TRAIN_ARGS)


train-header-model-with-dataset-and-default-dataset: build
	$(RUN) train-header-model.sh \
		--dataset "$(DATASET_DIR)" \
		--use-default-dataset \
		$(TRAIN_ARGS)


upload-header-model: build
	$(RUN) upload-header-model.sh "$(CLOUD_MODELS_PATH)"


shell: build
	$(RUN) bash


ci-build-and-test:
	make DOCKER_COMPOSE="$(DOCKER_COMPOSE_CI)" example-data-processing-end-to-end


ci-clean:
	$(DOCKER_COMPOSE_CI) down -v
