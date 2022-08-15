#!/bin/bash

# Decide network

NETWORK=$1
if [[ $@ == *"network=mainnet"* ]]; then
    NETWORK=mainnet
    NODE_ARGS="${@//network=mainnet/}"
elif [[ $@ == *"network=devnet"* ]]; then
    NETWORK=devnet
    NODE_ARGS="${@//network=devnet/}"
else
    echo "Error: unknown network switch." 1>&2
    exit 1
fi

echo "Network: ${NETWORK}"

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

echo "Node command-line arguments: ${NODE_ARGS}"
exec /elrond/node ${NODE_ARGS}
