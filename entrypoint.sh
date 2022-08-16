#!/bin/bash

NETWORK=""
PROGRAM=""
ARGS=""

# Decide network

if [[ $@ == *"network=mainnet"* ]]; then
    NETWORK=mainnet
    ARGS="${@//network=mainnet/}"
elif [[ $@ == *"network=devnet"* ]]; then
    NETWORK=devnet
    ARGS="${@//network=devnet/}"
else
    echo "Error: unknown network switch." 1>&2
    exit 1
fi

echo "Network: ${NETWORK}"

# Decide program to run

if [[ $@ == *"start-observer"* ]]; then
    PROGRAM=/elrond/node
    ARGS="${@//start-observer/}"
elif [[ $@ == *"start-rosetta"* ]]; then
    PROGRAM=/elrond/rosetta
    ARGS="${@//start-rosetta/}"
else
    echo "Error: unknown program." 1>&2
    exit 1
fi

echo "Program: ${PROGRAM}"

# Create observer key (if missing)

if [ ! -f "/data/observerKey.pem" ]
then
    /elrond/keygenerator
    mv ./validatorKey.pem /data/observerKey.pem
    echo "Created observer key."
else
    echo "Observer key already existing."
fi

# Symlink config (mainnet vs. devnet)

if [ "$NETWORK" == "mainnet" ]; then
    ln -sf /elrond/config-mainnet /elrond/config
elif [ "$NETWORK" == "devnet" ]; then
    ln -sf /elrond/config-devnet /elrond/config
fi

echo "Created symlink to config folder."

# Check existence of /data/db

if [ ! -d "/data/db" ]; then
    echo "Make sure the directory /data/db exists and contains a (recent) blockchain archive." 1>&2
    exit 1
fi

# Run the main process (Node)

echo "Node command-line arguments: ${ARGS}"
exec ${PROGRAM} ${ARGS}
