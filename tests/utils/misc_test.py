from sciencebeam_trainer_grobid.utils.misc import (
    parse_dict
)


class TestParseDict:
    def test_should_return_empty_dict_for_empty_expr(self):
        assert parse_dict('') == {}

    def test_should_parse_single_key_value_pair(self):
        assert parse_dict('key1=value1') == {'key1': 'value1'}

    def test_should_allow_equals_sign_in_value(self):
        assert parse_dict('key1=value=1') == {'key1': 'value=1'}

    def test_should_parse_multiple_key_value_pair(self):
        assert parse_dict(
            'key1=value1|key2=value2', delimiter='|'
        ) == {'key1': 'value1', 'key2': 'value2'}

    def test_should_ignore_spaces(self):
        assert parse_dict(
            ' key1 = value1 | key2 = value2 ', delimiter='|'
        ) == {'key1': 'value1', 'key2': 'value2'}
