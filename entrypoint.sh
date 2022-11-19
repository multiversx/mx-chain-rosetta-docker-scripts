#!/bin/bash

NETWORK=""
PROGRAM=""
ARGS=$@

# Decide program to run
if [[ $@ == *"start-observer"* ]]; then
    PROGRAM=/multiversx/node
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
        /multiversx/keygenerator
        mv ./validatorKey.pem /data/observerKey.pem
        echo "Created observer key."
    else
        echo "Observer key already existing."
    fi

    # For Node, symlink config (mainnet vs. devnet)
    if [ "$NETWORK" == "mainnet" ]; then
        ln -sf /multiversx/config-mainnet /multiversx/config
    elif [ "$NETWORK" == "devnet" ]; then
        ln -sf /multiversx/config-devnet /multiversx/config
    elif [ "$NETWORK" == "testnet" ]; then
        ln -sf /multiversx/config-testnet /multiversx/config
    fi

    echo "Created symlink to config folder."

    # For Node, check existence of /data/db
    if [ ! -d "/data/db" ]; then
        echo "Make sure the directory /data/db exists and contains a (recent) blockchain archive." 1>&2
        exit 1
    fi
elif [[ $@ == *"start-rosetta"* ]]; then
    PROGRAM=/multiversx/rosetta
    ARGS="${ARGS//start-rosetta/}"
else
    echo "Error: unknown program." 1>&2
    exit 1
fi

# Run the main process:
echo "Program: ${PROGRAM}"
echo "Command-line arguments: ${ARGS}"
exec ${PROGRAM} ${ARGS}
