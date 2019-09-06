import logging
import os
from abc import ABC, abstractmethod
from shutil import copyfileobj
from contextlib import contextmanager
from gzip import GzipFile
from lzma import LZMAFile
from typing import List

from six import string_types, text_type

import sciencebeam_trainer_grobid.utils.configure_warnings  # pylint: disable=unused-import

  # pylint: disable=wrong-import-order
from apache_beam.io.filesystem import CompressionTypes
from apache_beam.io.filesystems import FileSystems


LOGGER = logging.getLogger(__name__)


def is_external_location(filepath: str):
    return isinstance(filepath, string_types) and '://' in filepath


def path_join(parent, child):
    return os.path.join(str(parent), str(child))


def is_gzip_filename(filepath: str):
    return filepath.endswith('.gz')


def is_xz_filename(filepath: str):
    return filepath.endswith('.xz')


def strip_gzip_filename_ext(filepath: str):
    if not is_gzip_filename(filepath):
        raise ValueError('not a gzip filename: %s' % filepath)
    return os.path.splitext(filepath)[0]


def strip_xz_filename_ext(filepath: str):
    if not is_xz_filename(filepath):
        raise ValueError('not a xz filename: %s' % filepath)
    return os.path.splitext(filepath)[0]


class CompressionWrapper(ABC):
    @abstractmethod
    def strip_compression_filename_ext(self, filepath: str):
        pass

    @abstractmethod
    def wrap_fileobj(self, filename: str, fileobj):
        pass

    def get_beam_compression_type(self):
        return CompressionTypes.UNCOMPRESSED


class GzipCompressionWrapper(CompressionWrapper):
    def strip_compression_filename_ext(self, filepath: str):
        return strip_gzip_filename_ext(filepath)

    def wrap_fileobj(self, filename: str, fileobj):
        # Apache Beam already supports gzip, no need to wrap it
        # (it may decompress anyway if it was zipped as part of he transport encoding)
        return GzipFile(filename=filename, fileobj=fileobj)


class XzCompressionWrapper(CompressionWrapper):
    def strip_compression_filename_ext(self, filepath: str):
        return strip_xz_filename_ext(filepath)

    def wrap_fileobj(self, filename: str, fileobj):
        return LZMAFile(filename=fileobj)


class UncompressedCompressionWrapper(CompressionWrapper):
    def strip_compression_filename_ext(self, filepath: str):
        return filepath

    def wrap_fileobj(self, filename: str, fileobj):
        return fileobj


GZIP_COMPRESSION_WRAPPER = GzipCompressionWrapper()
XZ_COMPRESSION_WRAPPER = XzCompressionWrapper()
UNCOMPRESSED_COMPRESSION_WRAPPER = UncompressedCompressionWrapper()


def get_compression_wrapper(filepath: str):
    if is_gzip_filename(filepath):
        return GZIP_COMPRESSION_WRAPPER
    if is_xz_filename(filepath):
        return XZ_COMPRESSION_WRAPPER
    return UNCOMPRESSED_COMPRESSION_WRAPPER


@contextmanager
def open_file(
        filepath: str, mode: str,
        compression_wrapper: CompressionWrapper = None,
        beam_compression_type: str = None):
    if compression_wrapper is None:
        compression_wrapper = get_compression_wrapper(filepath)
    beam_compression_type = compression_wrapper.get_beam_compression_type()
    if mode in {'rb'}:
        with FileSystems.open(filepath, compression_type=beam_compression_type) as source_fp:
            LOGGER.info('source_fp: %s', source_fp)
            yield compression_wrapper.wrap_fileobj(filename=filepath, fileobj=source_fp)
    elif mode in {'wb'}:
        try:
            with FileSystems.create(filepath, compression_type=beam_compression_type) as target_fp:
                yield compression_wrapper.wrap_fileobj(filename=filepath, fileobj=target_fp)
        except FileNotFoundError:
            FileSystems.mkdirs(os.path.dirname(filepath))
            with FileSystems.create(filepath, compression_type=beam_compression_type) as target_fp:
                yield compression_wrapper.wrap_fileobj(filename=filepath, fileobj=target_fp)
    else:
        raise ValueError('unsupported mode: %s' % mode)


def copy_file(source_filepath: str, target_filepath: str, overwrite: bool = True):
    if not overwrite and FileSystems.exists(target_filepath):
        LOGGER.info('skipping already existing file: %s', target_filepath)
        return
    LOGGER.info('copying %s to %s', source_filepath, target_filepath)
    try:
        with open_file(text_type(source_filepath), mode='rb') as source_fp:
            with open_file(text_type(target_filepath), mode='wb') as target_fp:
                copyfileobj(source_fp, target_fp)
    except OSError as e:
        message = str(e)
        if not message or not message.lower().startswith('not a gzipped file'):
            raise
        # this may happen when `-Z` (gzip content-encoding) was used
        LOGGER.warning('copy failed due to (retrying without compression): %s', e)
        with open_file(text_type(
                source_filepath), mode='rb',
                compression_wrapper=UNCOMPRESSED_COMPRESSION_WRAPPER) as source_fp:
            with open_file(text_type(target_filepath), mode='wb') as target_fp:
                copyfileobj(source_fp, target_fp)


def list_files(directory_path: str) -> List[str]:
    pattern = os.path.join(directory_path, '*')
    return [x.path for x in FileSystems.match([pattern])[0].metadata_list]
