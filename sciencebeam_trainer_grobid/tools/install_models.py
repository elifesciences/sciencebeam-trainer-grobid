import argparse
import logging
import os
import pickle
from pathlib import Path
from typing import Dict, List

from sciencebeam_trainer_grobid.utils.misc import parse_dict, merge_dicts
from sciencebeam_trainer_grobid.utils.io import list_files, copy_file, get_compression_wrapper
from sciencebeam_trainer_grobid.utils.cli import (
    add_default_arguments,
    process_default_args,
    initialize_and_call_main
)


LOGGER = logging.getLogger(__name__)


SOURCE_URL_META_FILENAME = '.source-url'


def get_source_url_meta_file_path(target_directory: str) -> Path:
    return Path(target_directory, SOURCE_URL_META_FILENAME)


def copy_directory_with_source_meta(source_url: str, target_directory: str, force: bool = False):
    LOGGER.debug('source_url: %s, target_directory: %s', source_url, target_directory)
    source_url_meta_file = get_source_url_meta_file_path(target_directory)
    current_source_url = (
        source_url_meta_file.read_text().strip()
        if source_url_meta_file.exists()
        else None
    )
    if not force and current_source_url == source_url:
        LOGGER.debug(
            'current source_url of %s already (skipping): %s',
            target_directory, current_source_url
        )
        return []
    files = list_files(source_url)
    LOGGER.debug('files: %s', files)
    if not files:
        raise FileNotFoundError('no files found in %s' % source_url)
    os.makedirs(target_directory, exist_ok=True)
    for filename in files:
        if filename.endswith('/'):
            # sometimes the file list contain the directory itself
            continue
        relative_filename = os.path.basename(filename)
        relative_output_filename = get_compression_wrapper(
            relative_filename
        ).strip_compression_filename_ext(relative_filename)
        source_filepath = os.path.join(source_url, relative_filename)
        target_filepath = os.path.join(target_directory, relative_output_filename)
        LOGGER.info('copying %s to %s', source_filepath, target_filepath)
        copy_file(source_filepath, target_filepath)
    LOGGER.debug('setting %s to %s', source_url_meta_file, source_url)
    source_url_meta_file.write_text(source_url)
    return [
        os.path.join(target_directory, filename)
        for filename in files
    ]


def validate_pickle_file(pickle_file: str):
    with open(pickle_file, 'rb') as fp:
        pickle.load(fp)
    LOGGER.info('validated pickle file: %s', pickle_file)


def validate_pickle_files(pickle_files: List[str]):
    for pickle_file in pickle_files:
        validate_pickle_file(pickle_file)


def is_pickle_file(filename: str) -> bool:
    return filename.endswith('.pkl')


def filter_pickle_files(filenames: List[str]) -> List[str]:
    return [filename for filename in filenames if is_pickle_file(filename)]


def install_model(
        model_base_path: str, model_name: str, model_source_url: str,
        force: bool = False, validate_pickles: bool = False):
    LOGGER.debug(
        'model_base_path: %s, model_name: %s, model_source_url: %s',
        model_base_path, model_name, model_source_url
    )
    target_directory = os.path.join(model_base_path, model_name)
    target_files = copy_directory_with_source_meta(
        model_source_url, target_directory, force=force
    )
    if validate_pickles:
        validate_pickle_files(filter_pickle_files(target_files))
    LOGGER.info('copied model %s to %s', model_source_url, target_directory)


def install_models(
        model_base_path: str, model_source_dict: Dict[str, str],
        force: bool = False, validate_pickles: bool = False):
    LOGGER.debug('model_base_path: %s, model_source_dict: %s', model_base_path, model_source_dict)
    for model_name, model_source_url in model_source_dict.items():
        install_model(
            model_base_path, model_name, model_source_url,
            force=force, validate_pickles=validate_pickles
        )


def parse_model_source_expr(model_source_expr: str) -> Dict[str, str]:
    LOGGER.debug('model_source_expr: %s', model_source_expr)
    return parse_dict(model_source_expr, delimiter='|')


def parse_args(argv: List[str] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Install model(s)"
    )

    parser.add_argument(
        "--model-base-path",
        required=True,
        help=(
            "The base path for the local models. It will install the models to a"
            " sub-directory using the model name."
        )
    )

    parser.add_argument(
        "--install",
        nargs='+',
        required=True,
        type=parse_model_source_expr,
        help=(
            "The models to install, in the form: <model name>=<url>"
            "\n (multiple models can be specified by using the pipe ('|') separator"
            " or using the --install parameter multiple times"
        )
    )

    parser.add_argument(
        "--force",
        action="store_true",
        help="Force install model even if already installed from the source url"
    )

    parser.add_argument(
        "--validate-pickles",
        action="store_true",
        help="Validate .pkl files after copying (e.g. package structure may have changed)"
    )

    add_default_arguments(parser)
    return parser.parse_args(argv)


def run(args: argparse.Namespace):
    install_models(
        model_base_path=args.model_base_path,
        model_source_dict=merge_dicts(args.install),
        force=args.force,
        validate_pickles=args.validate_pickles
    )


def main(argv: List[str] = None):
    args = parse_args(argv)
    process_default_args(args)
    run(args)


if __name__ == "__main__":
    initialize_and_call_main(main)
