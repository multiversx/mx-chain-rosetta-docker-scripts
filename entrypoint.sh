#!/bin/bash

ARGS=$@

echo "Network: ${NETWORK}"
echo "Program: ${PROGRAM}"
echo "Args: ${ARGS}"

# Decide program to run
if [[ ${PROGRAM} == "node" ]]; then
    # For Node, create observer key (if missing)
    if [ ! -f "/data/observerKey.pem" ]
    then
        /elrond/keygenerator
        mv ./validatorKey.pem /data/observerKey.pem
        echo "Created observer key."
    else
        echo "Observer key already existing."
    fi

    # For Node, check existence of /data/db
    if [ ! -d "/data/db" ]; then
        echo "Make sure the directory /data/db exists and contains a (recent) blockchain archive." 1>&2
        exit 1
    fi
fi

DIRECTORY=/elrond/${NETWORK}
export LD_LIBRARY_PATH=${DIRECTORY}

# Run the main process:
cd ${DIRECTORY}
echo "Program: ${PROGRAM}"
echo "Command-line arguments: ${ARGS}"
echo "LD_LIBRARY_PATH: ${LD_LIBRARY_PATH}"
exec ./${PROGRAM} ${ARGS}
