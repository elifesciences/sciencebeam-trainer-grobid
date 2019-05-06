# ScienceBeam Trainer for GROBID

The Trainer for GROBID is a thin wrapper and Docker container around [GROBID Training commands](https://grobid.readthedocs.io/en/latest/Training-the-models-of-Grobid/). While this container is not complete yet (Header model only), it is cloud-ready.

## Prerequisites

* [Docker](https://www.docker.com/) and [Docker Compose](https://docs.docker.com/compose/)

## Recommended

* [Google Gloud SDK](https://cloud.google.com/sdk/docs/) for [gcloud](https://cloud.google.com/sdk/gcloud/)

## Using the Docker Container

### Header Model Training with Default Dataset

This isn't very useful unless you want to re-train the model. It is a good test to see how long training takes though.

Using Docker:

```bash
docker run --rm -it \
    elifesciences/sciencebeam-trainer-grobid_unstable:0.5.4 \
    train-header-model.sh \
        --use-default-dataset
```

Using Kubernetes:

```bash
kubectl run --rm --attach --restart=Never --generator=run-pod/v1 \
    --image=elifesciences/sciencebeam-trainer-grobid_unstable:0.5.4 \
    train-header-model -- \
    train-header-model.sh \
        --use-default-dataset
```

### Header Model Training with your own dataset

Using a mounted volume:

```bash
docker run --rm -it \
    -v /data/mydataset:/data/mydataset \
    elifesciences/sciencebeam-trainer-grobid_unstable:0.5.4 \
    train-header-model.sh \
        --dataset /data/mydataset \
        --use-default-dataset
```

You could also specify a cloud location that `gsutil` understands (assuming that the credentials are mounted too).

The `--use-default-dataset` flag is optional.

You may also add `--cloud-models-path <cloud path>` to copy the resulting model to a cloud storage.

## Make Targets

### Example End-to-End

```bash
make example-data-processing-end-to-end
```

Downloads example PDF, converts it to training data and runs the training. The resulting model won't be of much use and merely provides an example.

### Get Example Data

```bash
make get-example-data
```

Downloads example PDF to the `data` Docker volume.

### Generate GROBID Training Data

```bash
make generate-grobid-training-data
```

Converts the previously downloaded PDF from the Data volume to GROBID training data. The `tei` files will be stored in `tei-raw` in the dataset. Training on the raw XML wouldn't be of as that the annotations the model already knows. Usually one would review and correct those generated XML files using the [annotation guidelines](https://grobid.readthedocs.io/en/latest/training/General-principles/). The final `tei` files should be stored in the `tei` sub directory of the corpus in the dataset.

### Copy Raw Header Training Data to TEI

```bash
make copy-raw-header-training-data-to-tei
```

This copies the generated raw tei XML files in `tei-raw` to `tei`. This is just for demonstration purpose. The XML files should be reviewed (see above).

### Train Header Model with Dataset

```bash
make train-header-model-with-dataset
```

Trains the model over the dataset produced using the previous steps. The output will be the trained GROBID Header Model.

### Train Header Model with Default Dataset

```bash
make train-header-model-with-default-dataset
```

Instead of using our own dataset this will use the default dataset that comes with GROBID.

### Train Header Model with Dataset and Default Dataset

```bash
make train-header-model-with-dataset-and-default-dataset
```

A combination of the two - it will train a model based on the default dataset and our own dataset.

### Upload Header Model

```bash
make CLOUD_MODELS_PATH=gs://bucket/path/to/model upload-header-model
```

Upload the final header model to a location in the cloud. This is assuming that the credentials are mounted to the container. Because the [Google Gloud SDK](https://cloud.google.com/sdk/docs/) also has some support for AWS' S3, you could also specify an S3 location.
