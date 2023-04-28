## Find Competitor Matches

A Python package to identify equivalent competitor products so that we can honour our
low-price guarantee to customers.

## Running the project

### Running `find_competitor_matches` locally

Launch the main functionality, by running in the project root:

```shell
$ pipenv sync
$ pipenv run python -m find_competitor_matches
```

> Note: Environment variables can be injected into the containers using `.env` file in
> the root of the project. Use `.env.example` as a base for your `.env` file, adding any
> needed environment variable.

> Note 2: `NEXUS_USERNAME`, `NEXUS_PASSWORD` must be defined in the environment for the
> above commands to run.
