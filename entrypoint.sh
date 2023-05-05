#!/bin/bash

ARGS=$@

echo "Setup entrypoint ..."

if [[ ${NETWORK} != "mainnet" && ${NETWORK} != "devnet" ]]; then
    echo "Error: NETWORK isn't set. Should be 'mainnet' or 'devnet'." 1>&2
    exit 1
fi

if [[ ${PROGRAM} != "node" && ${PROGRAM} != "rosetta" ]]; then
    echo "Error: PROGRAM isn't set. Should be 'node' or 'rosetta'." 1>&2
    exit 1
fi

echo "NETWORK: ${NETWORK}"
echo "PROGRAM: ${PROGRAM}"
echo "PROGRAM arguments: ${ARGS}"

downloadDataIfNecessary() {
    echo "Download data if necessary ..."

    cd /data

    is_data_downloaded_marker_file=is_downloaded.txt

    if [[ -f $is_data_downloaded_marker_file ]]; then
        echo "Blockchain database already downloaded. Skipping ..."
        return
    fi

    if [[ "${DOWNLOAD_REGULAR_ARCHIVE}" = true ]] && [[ "${DOWNLOAD_NON_PRUNED_EPOCHS}" = true ]]; then
        echo "Error: DOWNLOAD_REGULAR_ARCHIVE and DOWNLOAD_NON_PRUNED_EPOCHS are mutually exclusive." 1>&2
        return 1
    fi

    if [[ "${DOWNLOAD_REGULAR_ARCHIVE}" = false ]] && [[ "${DOWNLOAD_NON_PRUNED_EPOCHS}" = false ]]; then
        echo "No download specified."
        return
    fi

    if [[ "${DOWNLOAD_REGULAR_ARCHIVE}" = true ]]; then
        downloadRegularArchive || return 1
    fi

    if [[ "${DOWNLOAD_NON_PRUNED_EPOCHS}" = true ]]; then
        downloadNonPrunedEpochs || return 1
    fi

    echo "Creating 'data downloaded' marker file ..."
    touch $is_data_downloaded_marker_file
}

# Download regular (daily) archive: epochs 0 -> current.
# Support for historical state lookup:
# - epoch 0 -> latest (recent) epoch: without support (pruned state)
# - latest (recent) epoch -> future: with support (as state isn't pruned anymore)
downloadRegularArchive() {
    echo "Download regular archive ..."

    if [[ -z "${DOWNLOAD_REGULAR_ARCHIVE_URL}" ]]; then
        echo "Error: DOWNLOAD_REGULAR_ARCHIVE_URL (commonly referred as the 'snapshot archive url') isn't set." 1>&2
        return 1
    fi

    echo "Downloading ${DOWNLOAD_REGULAR_ARCHIVE_URL} ..."
    wget -O archive "${DOWNLOAD_REGULAR_ARCHIVE_URL}" || return 1

    echo "Extracting archive ..."
    tar -xf archive || return 1
}

# Download a set of epochs with non-pruned state (with support for historical state lookup).
# Make sure to download 3 epoch archives older than the desired "starting point" for historical state lookup.
downloadNonPrunedEpochs() {
    echo "Download non-pruned epochs ..."

    if [[ -z "${DOWNLOAD_CHAIN_ID}" ]]; then
        echo "Error: DOWNLOAD_CHAIN_ID isn't set. Should be '1' or 'D'." 1>&2
        return 1
    fi

    if [[ -z "${DOWNLOAD_NON_PRUNED_EPOCHS_URL}" ]]; then
        echo "Error: DOWNLOAD_NON_PRUNED_EPOCHS_URL isn't set." 1>&2
        return 1
    fi

    if [[ -z "${DOWNLOAD_EPOCH_FIRST}" ]]; then
        echo "Error: DOWNLOAD_EPOCH_FIRST isn't set. Set it to <desired starting epoch for historical state lookup> - 3." 1>&2
        return 1
    fi

    if [[ -z "${DOWNLOAD_EPOCH_LAST}" ]]; then
        echo "Error: DOWNLOAD_EPOCH_LAST isn't set." 1>&2
        return 1
    fi

    mkdir -p db/${DOWNLOAD_CHAIN_ID}

    echo "Downloading Static.tar ..."
    wget ${DOWNLOAD_NON_PRUNED_EPOCHS_URL}/Static.tar || return 1

    for (( epoch = ${DOWNLOAD_EPOCH_FIRST}; epoch <= ${DOWNLOAD_EPOCH_LAST}; epoch++ ))
    do
        echo "Downloading Epoch_${epoch}.tar ..."
        wget ${DOWNLOAD_NON_PRUNED_EPOCHS_URL}/Epoch_${epoch}.tar || return 1
    done

    echo "Extracting Static.tar"
    tar -xf Static.tar --directory db/${DOWNLOAD_CHAIN_ID} || return 1

    for (( epoch = ${DOWNLOAD_EPOCH_FIRST}; epoch <= ${DOWNLOAD_EPOCH_LAST}; epoch++ ))
    do
        echo "Extracting Epoch_${epoch}.tar"
        tar -xf Epoch_${epoch}.tar --directory db/${DOWNLOAD_CHAIN_ID} || return 1
    done
}

# For Node (observer), perform additional steps
if [[ ${PROGRAM} == "node" ]]; then
    downloadDataIfNecessary || exit 1

    # Check existence of /data/db
    if [ ! -d "/data/db" ]; then
        echo "Error: make sure the directory /data/db exists." 1>&2
        exit 1
    fi

    DATABASE_SIZE=$(du -sb /data/db | cut -f1)

    # Check size of /data/db (check against a trivial size)
    if [[ $DATABASE_SIZE -lt 1048576 ]]; then
        echo "Error: make sure the directory /data/db contains a (recent) blockchain archive." 1>&2
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
