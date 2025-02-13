#!/bin/bash -e

# Workaround for pytest-xdist (it collects different tests in the workers if PYTHONHASHSEED is not set)
# https://github.com/pytest-dev/pytest/issues/920
# https://github.com/pytest-dev/pytest/issues/1075
export PYTHONHASHSEED=$(python -c 'import random; print(random.randint(1, 4294967295))')

# May help reproduce flaky CI builds if set in subsequent runs
echo PYTHONHASHSEED=$PYTHONHASHSEED

if [[ "not network" == *"$PATTERN"* ]]; then
    export http_proxy=http://1.2.3.4 https_proxy=http://1.2.3.4;
fi

if [ "$COVERAGE" ]; then
    COVERAGE="-s --cov=pandas --cov-report=xml --cov-append"
fi

# If no X server is found, we use xvfb to emulate it
if [[ $(uname) == "Linux" && -z $DISPLAY ]]; then
    export DISPLAY=":0"
    XVFB="xvfb-run "
fi

PYTEST_CMD="${XVFB}pytest -m \"$PATTERN\" -n $PYTEST_WORKERS --dist=loadfile $TEST_ARGS $COVERAGE $PYTEST_TARGET"

if [[ $(uname) != "Linux"  && $(uname) != "Darwin" ]]; then
    PYTEST_CMD="$PYTEST_CMD --ignore=pandas/tests/plotting/"
fi

echo $PYTEST_CMD
sh -c "$PYTEST_CMD"

if [[ "$PANDAS_DATA_MANAGER" != "array" ]]; then
    # The ArrayManager tests should have already been run by PYTEST_CMD if PANDAS_DATA_MANAGER was already set to array
    PYTEST_AM_CMD="PANDAS_DATA_MANAGER=array pytest -m \"$PATTERN and arraymanager\" -n $PYTEST_WORKERS  --dist=loadfile $TEST_ARGS $COVERAGE pandas"

    echo $PYTEST_AM_CMD
    sh -c "$PYTEST_AM_CMD"
fi
