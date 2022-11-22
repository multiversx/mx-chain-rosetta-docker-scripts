#!/bin/bash

ARGS=$@

echo "Network: ${NETWORK}"
echo "Program: ${PROGRAM}"
echo "Args: ${ARGS}"

# For Node (observer), perform additional steps
if [[ ${PROGRAM} == "node" ]]; then
    # Create observer key (if missing)
    if [ ! -f "/data/observerKey.pem" ]
    then
        /elrond/keygenerator
        mv ./validatorKey.pem /data/observerKey.pem
        echo "Created observer key."
    else
        echo "Observer key already existing."
    fi

    # Check existence of /data/db
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
