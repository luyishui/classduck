from pathlib import Path
import sys
import json


PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from services.validator_service import ValidatorService


def test_parse_weeks_supports_ranges_and_odd_even() -> None:
    service = ValidatorService()

    assert service._parse_weeks("1-6周(单),8,10-12周(双)") == [1, 3, 5, 8, 10, 12]


def test_parse_sections_supports_chinese_suffix_and_csv() -> None:
    service = ValidatorService()

    assert service._parse_sections("1-2节") == [1, 2]
    assert service._parse_sections("3,4") == [3, 4]


def test_extract_list_supports_nested_path() -> None:
    service = ValidatorService()
    payload = {"data": {"rows": [{"name": "A"}, {"name": "B"}]}}

    assert service._extract_list(payload, "data.rows") == [{"name": "A"}, {"name": "B"}]


def test_validate_and_parse_skips_incomplete_items() -> None:
    service = ValidatorService()
    raw_data = json.dumps(
        {
            "kbList": [
                {
                    "kcmc": "高等数学",
                    "cdmc": "A101",
                    "xm": "张老师",
                    "zcd": "1-16周",
                    "xqj": "1",
                    "jcs": "1-2节",
                },
                {
                    "kcmc": "",
                    "cdmc": "A102",
                    "xm": "李老师",
                    "zcd": "1-16周",
                    "xqj": "2",
                    "jcs": "3-4节",
                },
            ]
        },
        ensure_ascii=False,
    )

    result = service.validate_and_parse("xjtu", raw_data, year="2025", term="1")

    assert result.total_count == 2
    assert result.valid_count == 1
    assert result.invalid_count == 1
    assert result.courses[0].name == "高等数学"
    assert any("数据不完整" in warning for warning in result.warnings)