"""Identify equivalent competitor products."""

import logging

LOGGER = logging.getLogger(__name__)


class FindCompetitorMatchesHandler:
    """Handle find competitor matches logic.

    Expose `run()` method as an entrypoint to handle the logic.
    """

    def __init__(self):
        """Instantiate the class."""
        raise NotImplementedError(
            "Please implement FindCompetitorMatchesHandler.__init__()"
        )

    def run(self):
        """Run find competitor matches logic."""
        raise NotImplementedError("Please implement FindCompetitorMatchesHandler.run()")
