# rosetta-docker-content

Files referenced by (copied into the) [Rosetta's Docker setup](https://github.com/multiversx/mx-chain-rosetta-docker). **Not usable in other contexts.**

These files are kept separately from [mx-chain-rosetta-docker](https://github.com/multiversx/mx-chain-rosetta-docker) so that we can easily use versioned references towards them, and also to satisfy Rosetta's [build anywhere](https://docs.cloud.coinbase.com/rosetta/docs/docker-deployment#build-anywhere) requirement.

## `entrypoint.sh`

This script should be used as the _entrypoint_ of Rosetta's [Dockerfile](https://github.com/multiversx/mx-chain-rosetta-docker/blob/main/Dockerfile). It starts the requested program (`node` or `rosetta`), with the provided arguments, and with the appropriate configuration.

## `prefs.toml`

A configuration file, used to override specific configuration entries of the Observer.

## Notable references
 - [Docker: How to execute a shell command before the ENTRYPOINT](https://stackoverflow.com/a/41518225)
