DOCKER_COMPOSE_DEV = docker-compose
DOCKER_COMPOSE_CI = docker-compose -f docker-compose.yml
DOCKER_COMPOSE = $(DOCKER_COMPOSE_DEV)

VENV = venv
PIP = $(VENV)/bin/pip
PYTHON = $(VENV)/bin/python

OVERRIDE_MODELS =

RUN = $(DOCKER_COMPOSE) run --rm --no-deps \
	-e OVERRIDE_MODELS="$(OVERRIDE_MODELS)" \
	 sciencebeam-trainer-grobid

DEV_RUN = $(DOCKER_COMPOSE) run --rm --no-deps sciencebeam-trainer-grobid-dev

PDF_DATA_DIR = /data/pdf
DATASET_DIR = /data/dataset
XML_DATA_DIR = $(DATASET_DIR)/xml

TRAIN_ARGS =

USER_AGENT = Dummy/user-agent
SAMPLE_PDF_URL = https://cdn.elifesciences.org/articles/32671/elife-32671-v2.pdf

# Specify the location where to copy the model to
CLOUD_MODELS_PATH =

NOT_SLOW_PYTEST_ARGS = -m 'not slow'

ARGS =


venv-clean:
	@if [ -d "$(VENV)" ]; then \
		rm -rf "$(VENV)"; \
	fi


venv-create:
	python3 -m venv $(VENV)


dev-install:
	$(PIP) install -r requirements.txt
	$(PIP) install -r requirements.dev.txt
	$(PIP) install -e . --no-deps


dev-venv: venv-create dev-install


dev-flake8:
	$(PYTHON) -m flake8 sciencebeam_trainer_grobid tests setup.py


dev-pylint:
	$(PYTHON) -m pylint sciencebeam_trainer_grobid tests setup.py


dev-lint: dev-flake8 dev-pylint


dev-pytest:
	$(PYTHON) -m pytest -p no:cacheprovider $(ARGS)


dev-watch:
	$(PYTHON) -m pytest_watch --verbose --ext=.py,.xsl -- -p no:cacheprovider -k 'not slow' $(ARGS)


dev-watch-slow:
	$(PYTHON) -m pytest_watch --verbose --ext=.py,.xsl -- -p no:cacheprovider $(ARGS)


dev-test: dev-lint dev-pytest


build:
	$(DOCKER_COMPOSE) build \
		grobid-builder \
		sciencebeam-trainer-grobid \


build-dev:
	$(DOCKER_COMPOSE) build \
		grobid-builder \
		sciencebeam-trainer-grobid-dev-base \
		sciencebeam-trainer-grobid-dev


grobid-builder-build:
	@if [ "$(NO_BUILD)" != "y" ]; then \
		$(DOCKER_COMPOSE) build grobid-builder; \
	fi


example-data-processing-end-to-end: \
	get-example-data \
	generate-grobid-training-data \
	copy-raw-header-training-data-to-tei \
	train-header-model-with-dataset


get-example-data:
	$(RUN) bash -c '\
		mkdir -p "$(PDF_DATA_DIR)" \
		&& curl --fail --show-error --connect-timeout 60 --user-agent "$(USER_AGENT)" --location \
			"$(SAMPLE_PDF_URL)" --silent -o "$(PDF_DATA_DIR)/sample.pdf" \
		&& ls -l "$(PDF_DATA_DIR)" \
		'


generate-grobid-training-data:
	$(RUN) generate-grobid-training-data.sh \
		"${PDF_DATA_DIR}" \
		"$(DATASET_DIR)"


copy-raw-header-training-data-to-tei:
	$(RUN) bash -c '\
		mkdir -p "$(DATASET_DIR)/header/corpus/tei" && \
		cp "$(DATASET_DIR)/header/corpus/tei-raw/"*.xml "$(DATASET_DIR)/header/corpus/tei/" \
		'


train-header-model-with-dataset:
	$(RUN) train-header-model.sh \
		--dataset "$(DATASET_DIR)" \
		$(TRAIN_ARGS)


train-header-model-with-default-dataset:
	$(RUN) train-header-model.sh \
		--use-default-dataset \
		$(TRAIN_ARGS)


train-header-model-with-dataset-and-default-dataset:
	$(RUN) train-header-model.sh \
		--dataset "$(DATASET_DIR)" \
		--use-default-dataset \
		$(TRAIN_ARGS)


upload-header-model:
	$(RUN) upload-header-model.sh "$(CLOUD_MODELS_PATH)"


copy-raw-segmentation-training-data-to-tei:
	$(RUN) bash -c '\
		mkdir -p "$(DATASET_DIR)/segmentation/corpus/tei" && \
		cp "$(DATASET_DIR)/segmentation/corpus/tei-raw/"*.xml "$(DATASET_DIR)/segmentation/corpus/tei/" \
		'


train-segmentation-model-with-dataset:
	$(RUN) train-model.sh \
		--dataset "$(DATASET_DIR)" \
		--model segmentation \
		$(TRAIN_ARGS)


train-segmentation-model-with-default-dataset:
	$(RUN) train-model.sh \
		--use-default-dataset \
		--model segmentation \
		$(TRAIN_ARGS)


train-segmentation-model-with-dataset-and-default-dataset:
	$(RUN) train-model.sh \
		--dataset "$(DATASET_DIR)" \
		--use-default-dataset \
		--model segmentation \
		$(TRAIN_ARGS)


upload-segmentation-model:
	$(RUN) upload-model.sh "$(CLOUD_MODELS_PATH)" "segmentation"


shell:
	$(RUN) bash


grobid-builder-shell: grobid-builder-build
	$(DOCKER_COMPOSE) run --rm grobid-builder bash


shell-dev:
	$(DEV_RUN) bash


pylint:
	$(DEV_RUN) pylint sciencebeam_trainer_grobid tests setup.py


flake8:
	$(DEV_RUN) flake8 sciencebeam_trainer_grobid tests setup.py


pytest:
	$(DEV_RUN) pytest -p no:cacheprovider $(ARGS)


pytest-not-slow:
	@$(MAKE) ARGS="$(ARGS) $(NOT_SLOW_PYTEST_ARGS)" pytest


.watch:
	$(DEV_RUN) pytest-watch -- -p no:cacheprovider -p no:warnings $(ARGS)


watch-slow:
	@$(MAKE) .watch


watch:
	@$(MAKE) ARGS="$(ARGS) $(NOT_SLOW_PYTEST_ARGS)" .watch


lint: flake8 pylint


test: lint pytest


ci-build:
	make DOCKER_COMPOSE="$(DOCKER_COMPOSE_CI)" build build-dev


ci-test-only:
	make DOCKER_COMPOSE="$(DOCKER_COMPOSE_CI)" \
		test \
		example-data-processing-end-to-end


ci-build-and-test: ci-build ci-test-only


ci-clean:
	$(DOCKER_COMPOSE_CI) down -v
