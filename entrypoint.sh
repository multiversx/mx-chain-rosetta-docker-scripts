#!/bin/bash

ARGS=$@

if [[ ${NETWORK} != "mainnet" && ${NETWORK} != "devnet" ]]; then
    echo "Error: NETWORK isn't set. Should be 'mainnet' or 'devnet'."
    exit 1
fi

if [[ ${PROGRAM} != "node" && ${PROGRAM} != "rosetta" ]]; then
    echo "Error: PROGRAM isn't set. Should be 'node' or 'rosetta'."
    exit 1
fi

echo "NETWORK: ${NETWORK}"
echo "PROGRAM: ${PROGRAM}"
echo "PROGRAM arguments: ${ARGS}"

downloadDataIfNecessary() {
    cd /data

    is_data_downloaded_marker_file=is_downloaded.txt

    if [[ -f $used_external_snapshot_flag ]]; then
        echo "Blockchain database already downloaded. Skipping ..."
        return
    fi

    if [[ -n ${DOWNLOAD_REGULAR_ARCHIVE} ]]; then
        downloadRegularArchive || return 1
    fi

    if [[ -n ${DOWNLOAD_NON_PRUNED_EPOCHS} ]]; then
        downloadNonPrunedEpochs || return 1
    fi

    touch $is_data_downloaded_marker_file
}

# Download regular (daily) archive: epochs 0 -> current.
# Support for historical state lookup:
# - epoch 0 -> latest (recent) epoch: without support (pruned state)
# - latest (recent) epoch -> future: with support (as state isn't pruned anymore)
downloadRegularArchive() {
    if [[ -z "${REGULAR_ARCHIVE_URL}" ]]; then
        echo "Error: REGULAR_ARCHIVE_URL (commonly referred as the 'snapshot archive url') isn't set."
        return 1
    fi

    echo "Downloading ${REGULAR_ARCHIVE_URL} ..."
    wget -c -O archive.tar.gz "${REGULAR_ARCHIVE_URL}" || return 1

    echo "Extracting archive ..."
    tar -xzf archive.tar.gz || return 1

    echo "Removing archive ..."
    rm archive.tar.gz
}

# Download a set of epochs with non-pruned state (with support for historical state lookup).
# Make sure to download 3 epoch archives older than the desired "starting point" for historical state lookup.
downloadNonPrunedEpochs() {
    if [[ -z "${CHAIN_ID}" ]]; then
        echo "Error: CHAIN_ID isn't set. Should be '1' or 'D'."
        return 1
    fi

    if [[ -z "${NON_PRUNED_URL_BASE}" ]]; then
        echo "Error: NON_PRUNED_URL_BASE isn't set."
        return 1
    fi

    if [[ -z "${EPOCH_FIRST}" ]]; then
        echo "Error: EPOCH_FIRST isn't set. Set it to <desired starting epoch for historical state lookup> - 3."
        return 1
    fi

    if [[ -z "${EPOCH_LAST}" ]]; then
        echo "Error: EPOCH_LAST isn't set."
        return 1
    fi

    mkdir -p db/${CHAIN_ID}

    echo "Downloading Static.rar ..."
    wget ${NON_PRUNED_URL_BASE}/Static.tar || return 1

    for (( epoch = ${EPOCH_FIRST}; epoch <= ${EPOCH_LAST}; epoch++ ))
    do
        echo "Downloading Epoch_${epoch}.tar ..."
        wget ${NON_PRUNED_URL_BASE}/Epoch_${epoch}.tar || return 1
    done

    echo "Extracting Static.rar"
    tar -xf Static.tar --directory db/${CHAIN_ID} || return 1

    echo "Removing Static.rar"
    rm Static.tar

    for (( epoch = ${EPOCH_FIRST}; epoch <= ${EPOCH_LAST}; epoch++ ))
    do
        echo "Extracting Epoch_${epoch}.tar"
        tar -xf Epoch_${epoch}.tar --directory db/${CHAIN_ID} || return 1

        echo "Removing Epoch_${epoch}.tar"
        rm Epoch_${epoch}.tar
    done
}

# For Node (observer), perform additional steps
if [[ ${PROGRAM} == "node" ]]; then
    # Create observer key (if missing)
    if [ ! -f "/data/observerKey.pem" ]
    then
        /app/keygenerator || exit 1
        mv ./validatorKey.pem /data/observerKey.pem || exit 1
        echo "Created observer key."
    else
        echo "Observer key already existing."
    fi

    downloadDataIfNecessary || exit 1

    # Check existence of /data/db
    if [ ! -d "/data/db" ]; then
        echo "Make sure the directory /data/db exists and contains a (recent) blockchain archive." 1>&2
        exit 1
    fi
fi

DIRECTORY=/app/${NETWORK}
export LD_LIBRARY_PATH=${DIRECTORY}

# Run the main process:
cd ${DIRECTORY}
echo "Program: ${PROGRAM}"
echo "Command-line arguments: ${ARGS}"
echo "LD_LIBRARY_PATH: ${LD_LIBRARY_PATH}"
exec ./${PROGRAM} ${ARGS}
