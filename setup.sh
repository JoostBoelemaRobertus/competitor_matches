#!/usr/bin/env bash

set -e

# Check that python environment is properly configured.
[[ "$(pyenv root)" =~ $(whoami)/.pyenv ]] || { echo "Pyenv could not be found in the expected directory!"; exit 1; }
[[ "$(which python)" =~ $(whoami)/.pyenv/shims/python ]] || { echo "Python managed by pyenv is not used!"; exit 1; }
[[ "$(pipenv --version)" =~ "pipenv, version" ]] || { echo "Pipenv could not be found!"; exit 1; }
echo "Python environment setup check passed successfully!"

# Enter project root folder.
pushd find-competitor-matches > /dev/null

# Check .env exists and all mandatory variables are available.
export $(grep -v '^#' .env | xargs)
[ "${PEE_MARKET:-}"   ] || { echo "PEE_MARKET is not set!"; exit 1; }
[ "${PEE_ENVIRONMENT:-}" ] || { echo "PEE_ENVIRONMENT is not set!"; exit 1; }
[ "${DWH_USERNAME:-}" ]  || { echo "DWH_USERNAME is not set!"; exit 1; }
echo "Env variables setup check passed successfully!"

# Check that pipenv is able to install new packages.
pipenv sync --dev

# Check that Docker daemon is available for picnic-guide.
pipenv run guide lint

# Check project executes with expected output.
pipenv run python -m find_competitor_matches 2>&1 > /dev/null |
 grep -q "NotImplementedError: Please implement FindCompetitorMatchesHandler.__init__()" ||
 { echo "Service 'find_competitor_matches' exited with not an expected output!"; exit 1; }
echo "Python project dependencies setup check passed successfully!"

# Exit project root folder.
popd > /dev/null

# Check SQL queries are up to date.
if ! snowsql -v &> /dev/null
then
    echo "Package snowsql could not be found! Skip SQL query check."
else
  echo "Package snowsql is found. Check SQL queries..."
  snowsql -v
  export SNOWSQL_ACCOUNT=uj82639.eu-west-1
  export SNOWSQL_USER=$DWH_USERNAME
  export SNOWSQL_DATABASE=picnic_nl_prod
  export SNOWSQL_ROLE=ANALYST
  export SNOWSQL_WAREHOUSE=ANALYSIS
  export SNOWSQL_SCHEMA=public

  # Execute queries with user's credentials using externalbrowser authenticator flow.
  rows_produced=$(
  snowsql --authenticator externalbrowser \
   -f find-competitor-matches/find_competitor_matches/queries/find_all_competitor_products.sql \
   -f find-competitor-matches/find_competitor_matches/queries/find_all_picnic_products.sql \
   -f find-competitor-matches/find_competitor_matches/queries/find_current_matches.sql \
   -f find-competitor-matches/find_competitor_matches/queries/find_disappearing_competitor_products.sql \
   | grep -c "Row(s) produced."
   )
  if [[ rows_produced -eq 4 ]]; then
    echo "SQL queries check passed successfully!"
  else
    { echo "SQL queries check failed!"; exit 1; }
  fi
fi

echo "All checks have passed!"
