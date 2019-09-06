import warnings


warnings.filterwarnings(
    'ignore', 'Some syntactic constructs of Python 3 are not yet fully supported by Apache Beam',
    category=UserWarning
)
