"""
find_competitor_matches/__init__.py
---

Contains FindCompetitorMatchesHandler, which implements the main task: to identify
equivalent competitor products so that we can honour our low-price guarantee to customers.
"""

import logging

LOGGER = logging.getLogger(__name__)


class FindCompetitorMatchesHandler:
    def __init__(self):
        raise NotImplementedError("Please fix FindCompetitorMatchesHandler.__init__()")

    def run(self):
        raise NotImplementedError("Please fix FindCompetitorMatchesHandler.run()")
