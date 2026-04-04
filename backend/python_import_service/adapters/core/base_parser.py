from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Any


class BaseAdapterParser(ABC):
    """Base interface for adapter parsers."""

    @abstractmethod
    def parse(self, payload: Any) -> list[dict[str, Any]]:
        """Parse adapter payload into normalized course dictionaries."""
        raise NotImplementedError
