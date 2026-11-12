"""The children's English names.

In Turkish the boy is Ali and the girl is Ayşe; in English they are Leo and
Mia (Yunus, 12 November 2026: "İngilizcede yine Ali olmasın"). The sources
keep "Ali" in their English lines; the builders pass their data through
[rename] so every English text says Leo.
"""
import re


def english(text):
    return re.sub(r'\bAli\b', 'Leo', text)


def rename(node):
    """Renames in place every {'tr': ..., 'en': ...} pair inside [node]."""
    if isinstance(node, dict):
        if 'en' in node and 'tr' in node and isinstance(node['en'], str):
            node['en'] = english(node['en'])
        for value in node.values():
            rename(value)
    elif isinstance(node, list):
        for value in node:
            rename(value)
    return node
