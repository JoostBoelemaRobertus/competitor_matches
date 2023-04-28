# Tech Academy Python Training

### Welcome to the _Practical Python_ course, brought to you by the Picnic Tech Academy.

The _Practical Python_ course is a five-day, instructor-led workshop here at Picnic.
Together with like-minded peers, you’ll follow a hands-on curriculum using a real-world
Picnic use case to learn Python techniques, approaches and best practices designed to
take your Python skills to the next level.

## Project setup

As part of the course, you will form small groups to work together on the project. You
may find the project's barebone in the `find-competitor-matches` folder. Follow these
steps to ensure that you have all the prerequisites to work on the project.

Make sure that you followed
[development environment setup](https://picnic.atlassian.net/wiki/spaces/PY/pages/3468198008/2.1+-+Development+Environment+Setup).

Make sure that you followed
[general Python installation guide](https://picnic.atlassian.net/wiki/spaces/PY/pages/4016472261/Getting+started+with+Python+at+Picnic).

Launch Docker (Docker Desktop). We need it to run to verify the completeness of the setup at the next steps.

1. Navigate to the project's root from the current directory:

   ```shell
   cd find_competitor_matches
   ```

2. Create a new file named `.env` by cloning `env.example`.

   ```shell
   cp env.example .env
   ```

3. Fill the missing environment variables with your secrets.
4. Launch the main functionality, by running in the project root:

   ```shell
   $ pipenv sync
   $ pipenv run python -m find_competitor_matches
   ```

   Verify that the code ends up with the following output line:

   ```text
   "NotImplementedError: Please implement FindCompetitorMatchesHandler.__init__()"
   ```

5. [Optional] Install `snowsql` CLI tool to verify that your DWH account is permitted to
   perform project's SQL queries. Follow the
   [Snowflake documentation](https://docs.snowflake.com/en/user-guide/snowsql-install-config)
   to install `snowsql` to your system.
6. Verify the setup by running `./setup.sh`. Navigate to `picnic-tech-academy-python-training` and run:

   ```shell
   ./setup.sh
   ```

   Make sure that all checks have passed for you. If so, your project is fully prepared!

Good luck with the Python Training!
