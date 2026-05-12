"""Small XML helpers for Huawei CPE responses and payloads."""

from __future__ import annotations

from html import unescape
from typing import Iterable
from xml.etree import ElementTree
from xml.sax.saxutils import escape


class XMLParseError(ValueError):
    """Raised when a CPE XML response cannot be parsed."""


def parse_root(xml_text: str) -> ElementTree.Element:
    try:
        return ElementTree.fromstring(xml_text.strip())
    except ElementTree.ParseError as exc:
        raise XMLParseError(f"Invalid XML response: {exc}") from exc


def tag_text(root: ElementTree.Element | None, tag: str, default: str = "") -> str:
    if root is None:
        return default
    element = root.find(f".//{tag}")
    if element is None or element.text is None:
        return default
    return unescape(element.text.strip())


def parse_flat(xml_text: str) -> dict[str, str]:
    root = parse_root(xml_text)
    return {child.tag: unescape((child.text or "").strip()) for child in root}


def xml_text(value: object) -> str:
    return escape(str(value), {'"': "&quot;", "'": "&apos;"})


def join_xml(elements: Iterable[str]) -> str:
    return "".join(elements)
