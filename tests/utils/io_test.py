import gzip
from pathlib import Path

from sciencebeam_trainer_grobid.utils.io import (
    is_external_location,
    copy_file
)


SOURCE_FILENAME_1 = 'source_file1.bin'
TARGET_FILENAME_1 = 'target_file1.bin'

DATA_1 = b'data 1'


class TestIsExternalLocation:
    def test_should_return_false_for_name(self):
        assert not is_external_location('name')

    def test_should_return_true_for_url(self):
        assert is_external_location('http://name')


class TestCopyFile:
    def test_should_decompress_gzipped_file(self, temp_dir: Path):
        with gzip.open(str(temp_dir.joinpath(SOURCE_FILENAME_1 + '.gz')), 'wb') as fp:
            fp.write(DATA_1)
        copy_file(
            temp_dir.joinpath(SOURCE_FILENAME_1 + '.gz'),
            temp_dir.joinpath(TARGET_FILENAME_1)
        )
        assert temp_dir.joinpath(TARGET_FILENAME_1).read_bytes() == DATA_1

    def test_should_fallback_if_decompression_fails(self, temp_dir: Path):
        temp_dir.joinpath(SOURCE_FILENAME_1 + '.gz').write_bytes(DATA_1)
        copy_file(
            temp_dir.joinpath(SOURCE_FILENAME_1 + '.gz'),
            temp_dir.joinpath(TARGET_FILENAME_1)
        )
        assert temp_dir.joinpath(TARGET_FILENAME_1).read_bytes() == DATA_1
