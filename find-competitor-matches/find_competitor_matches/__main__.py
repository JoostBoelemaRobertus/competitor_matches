"""Entry point for find_competitor_matches.

Load some configuration, and call `FindCompetitorMatchesHandler` to run the job.
"""

import logging
import sys
import warnings
from pathlib import Path

from picnic.tools import config_loader

from find_competitor_matches.handler import FindCompetitorMatchesHandler

LOGGER = logging.getLogger(__name__)
PROJECT_ROOT_DIR = Path(__file__).parent.resolve()
CONFIG_DIR = PROJECT_ROOT_DIR / "config"


def configure_project() -> dict:
    """Handle common project configurations.

    Return: a dictionary containing configuration parameters.
    """
    # Enable showing the first occurrence of a specific DeprecationWarning
    warnings.simplefilter("once", DeprecationWarning)

    # Logging to standard error stream
    logging.basicConfig(stream=sys.stderr, level=logging.DEBUG)

    # Load config
    config = config_loader.load_config(config_dir=CONFIG_DIR)
    LOGGER.debug("Config is successfully loaded.")

    return config


def main():
    """Run project."""
    _ = configure_project()

    LOGGER.info("Starting 'find-competitor-matches' service.".upper())

    handler = FindCompetitorMatchesHandler()
    handler.run()

    LOGGER.info("'find-competitor-matches' service finished.".upper())


main()
