#!/bin/bash

NETWORK=""
PROGRAM=""
ARGS=$@

# Decide program to run
if [[ $@ == *"start-observer"* ]]; then
    ARGS="${ARGS//start-observer/}"

    # For Node, decide network
    if [[ $@ == *"network=mainnet"* ]]; then
        NETWORK=mainnet
        ARGS="${ARGS//network=mainnet/}"
    elif [[ $@ == *"network=devnet"* ]]; then
        NETWORK=devnet
        ARGS="${ARGS//network=devnet/}"
    elif [[ $@ == *"network=testnet"* ]]; then
        NETWORK=testnet
        ARGS="${ARGS//network=testnet/}"
    else
        echo "Error: unknown network switch." 1>&2
        exit 1
    fi

    echo "Network: ${NETWORK}"

    # For Node, create observer key (if missing)
    if [ ! -f "/data/observerKey.pem" ]
    then
        /elrond/keygenerator
        mv ./validatorKey.pem /data/observerKey.pem
        echo "Created observer key."
    else
        echo "Observer key already existing."
    fi

    # For Node, decide current directory, executable and export LD_LIBRARY_PATH (mainnet vs. devnet vs. testnet)
    DIRECTORY=/elrond/${NETWORK}
    PROGRAM=${DIRECTORY}/node
    export LD_LIBRARY_PATH=${DIRECTORY}

    # For Node, check existence of /data/db
    if [ ! -d "/data/db" ]; then
        echo "Make sure the directory /data/db exists and contains a (recent) blockchain archive." 1>&2
        exit 1
    fi
elif [[ $@ == *"start-rosetta"* ]]; then
    DIRECTORY=/elrond
    PROGRAM=${DIRECTORY}/rosetta
    ARGS="${ARGS//start-rosetta/}"
else
    echo "Error: unknown program." 1>&2
    exit 1
fi

# Run the main process:
cd ${DIRECTORY}
echo "Program: ${PROGRAM}"
echo "Command-line arguments: ${ARGS}"
echo "LD_LIBRARY_PATH: ${LD_LIBRARY_PATH}"
exec ${PROGRAM} ${ARGS}
