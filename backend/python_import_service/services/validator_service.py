"""
导入校验服务 —— 整个后端的核心业务模块

【设计思路】
接收前端从 WebView JS 拿到的"原始教务 JSON 字符串"，按照学校配置中的
field_mapping 做字段映射，再将中文周次、节次字符串解析为整型数组，
输出标准化的 StandardCourse 列表。

主流程：
  raw_data (str) → json.loads → _extract_list(按 data_path 取数组)
  → 逐条 _parse_single_course(按 field_mapping 提取字段)
    → _parse_weeks  把 "1-16周" / "2-16周(双)" / "1,3,5" 等变为 [1,2,...16]
    → _parse_sections 把 "1-2" / "3,4" 变为 [1,2] / [3,4]
  → 封装为 ImportResult(courses, warnings, valid/invalid_count)

关键设计决策：
1. raw_data 接收的是 JSON 字符串而非对象——因为 WebView JS 通过
   callHandler 把序列化后的字符串传给 Flutter，Flutter 再原样 POST 给后端。
2. data_path 支持嵌套取值（如 "kbList" 或 "data.rows"），避免每个学校
   适配不同的 JSON 结构时改代码。
3. 周次解析支持"单周/双周/奇偶周"中文标注——这是教务系统常见格式。
4. 单条解析失败不中断整批——跳过并记录 warning，前端可决定是否接受。
"""

import json
import re
from typing import Any

from models.course import ImportResult, StandardCourse
from models.school import FieldMapping
from services.school_service import SchoolService


class ValidatorService:
    def __init__(self) -> None:
        self.school_service = SchoolService()

    def validate_and_parse(
        self,
        school_id: str,
        raw_data: str,
        year: str = "",
        term: str = "",
    ) -> ImportResult:
        """
        核心入口：接收学校ID和原始JSON字符串，输出标准化导入结果。

        步骤：
        1. 根据 school_id 加载 SchoolConfig（含 field_mapping / data_path）
        2. json.loads 解析 raw_data
        3. 按 data_path 从 payload 中提取课程数组
        4. 逐条按 field_mapping 做字段映射和周次/节次解析
        5. 统计 valid/invalid/warnings，组装 ImportResult 返回
        """
        config = self.school_service.get_config(school_id)
        if not config:
            raise ValueError(f"未找到学校配置: {school_id}")

        try:
            payload = json.loads(raw_data)
        except json.JSONDecodeError as exc:
            raise ValueError(f"JSON解析失败: {exc}") from exc

        raw_list = self._extract_list(payload, config.data_path)
        if not isinstance(raw_list, list):
            raise ValueError(f"期望数组，收到: {type(raw_list).__name__}")
        if len(raw_list) == 0:
            raise ValueError("课表数据为空，请确认学年学期是否正确")

        courses: list[StandardCourse] = []
        warnings: list[str] = []
        invalid_count = 0
        for index, item in enumerate(raw_list):
            try:
                if not isinstance(item, dict):
                    raise ValueError("课程项不是对象")
                course = self._parse_single_course(item, config.field_mapping)
                if course is None:
                    invalid_count += 1
                    warnings.append(f"第{index + 1}条: 数据不完整，已跳过")
                    continue
                courses.append(course)
            except Exception as exc:
                invalid_count += 1
                warnings.append(f"第{index + 1}条: {exc}")

        semester_name = ""
        if year and term:
            try:
                semester_name = f"{year}-{int(year) + 1} 第{term}学期"
            except ValueError:
                semester_name = f"{year} 第{term}学期"

        return ImportResult(
            semester_name=semester_name,
            school_id=school_id,
            courses=courses,
            total_count=len(raw_list),
            valid_count=len(courses),
            invalid_count=invalid_count,
            warnings=warnings,
        )

    def _extract_list(self, payload: Any, data_path: str) -> Any:
        """按 data_path 从 JSON 对象中逐层取值。例如 data_path="kbList" 时取 payload["kbList"]。"""
        if not data_path:
            return payload
        current = payload
        for key in data_path.split("."):
            if not isinstance(current, dict):
                return current
            current = current.get(key)
        return current

    def _parse_single_course(self, item: dict[str, Any], mapping: FieldMapping) -> StandardCourse | None:
        """
        将单条原始课程 dict 按 field_mapping 转换为 StandardCourse。
        返回 None 表示数据不完整（课程名为空）；抛异常表示解析失败（周次/节次无效）。
        """
        name = str(item.get(mapping.name, "")).strip()
        if not name:
            return None

        position = str(item.get(mapping.position, "")).strip()
        teacher = str(item.get(mapping.teacher, "")).strip()
        weeks = self._parse_weeks(str(item.get(mapping.weeks, "")))
        if not weeks:
            raise ValueError(f"周数解析失败: '{item.get(mapping.weeks, '')}'")

        day_raw = item.get(mapping.day, 0)
        day = int(day_raw) if str(day_raw).strip() else 0
        if day < 1 or day > 7:
            raise ValueError(f"星期无效: {day_raw}")

        sections = self._parse_sections(str(item.get(mapping.sections, "")))
        if not sections:
            raise ValueError(f"节次解析失败: '{item.get(mapping.sections, '')}'")

        return StandardCourse(
            name=name,
            position=position,
            teacher=teacher,
            weeks=weeks,
            day=day,
            start_section=min(sections),
            duration=max(sections) - min(sections) + 1,
        )

    def _parse_weeks(self, week_str: str) -> list[int]:
        """
        将教务系统常见的周次字符串解析为整型列表。
        支持格式："1-16周"、"2-16周(双)"、"1,3,5,7"、"1-8周,10-16周"。
        "单"只保留奇数周，"双"只保留偶数周。结果范围限定 1-30。
        """
        weeks: set[int] = set()
        normalized = week_str.replace("周", "").replace("，", ",")
        for segment in normalized.split(","):
            text = segment.strip()
            if not text:
                continue
            odd_only = "单" in text
            even_only = "双" in text
            clean = re.sub(r"[()（）单双]", "", text).strip()
            if "-" in clean:
                parts = clean.split("-", 1)
                try:
                    start = int(parts[0].strip())
                    end = int(parts[1].strip())
                except ValueError:
                    continue
                for value in range(start, end + 1):
                    if odd_only and value % 2 == 0:
                        continue
                    if even_only and value % 2 == 1:
                        continue
                    if 1 <= value <= 30:
                        weeks.add(value)
                continue
            try:
                single = int(clean)
            except ValueError:
                continue
            if 1 <= single <= 30:
                weeks.add(single)
        return sorted(weeks)

    def _parse_sections(self, section_str: str) -> list[int]:
        """
        将节次字符串解析为整型列表。支持 "1-2"（范围）、"3,4"（逗号分隔）、"5"（单节）。
        返回值经过 1-15 范围过滤。section_str 中可能含"节"字会被 strip 后的 text 处理。
        """
        sections: list[int] = []
        text = section_str.strip()
        if not text:
            return sections
        # 移除中文"节"字和空格，统一处理
        text = text.replace("节", "").strip()
        if "-" in text:
            parts = text.split("-", 1)
            try:
                start = int(parts[0].strip())
                end = int(parts[1].strip())
                sections = list(range(start, end + 1))
            except ValueError:
                sections = []
        elif "," in text:
            for item in text.split(","):
                try:
                    sections.append(int(item.strip()))
                except ValueError:
                    continue
        else:
            try:
                sections.append(int(text))
            except ValueError:
                return []
        return [section for section in sections if 1 <= section <= 15]