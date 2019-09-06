import logging
from pathlib import Path

import pytest
from py._path.local import LocalPath

from .compat_patch_mock import patch_magicmock_fixture  # noqa pylint: disable=unused-import


LOGGER = logging.getLogger(__name__)


@pytest.fixture(scope='session', autouse=True)
def setup_logging():
    logging.root.handlers = []
    logging.basicConfig(level='INFO')
    logging.getLogger('tests').setLevel('DEBUG')
    logging.getLogger('sciencebeam_trainer_grobid').setLevel('DEBUG')


@pytest.fixture
def temp_dir(tmpdir: LocalPath):
    # convert to standard Path
    return Path(str(tmpdir))
