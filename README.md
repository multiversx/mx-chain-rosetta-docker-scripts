# rosetta-docker-scripts

Scripts referenced by [Rosetta's Docker setup](https://github.com/ElrondNetwork/rosetta-docker). **Not usable in other contexts.**

These scripts are kept separately (in this repository) so that we can easily use versioned references towards them, and also to satisfy Rosetta's [build anywhere](https://www.rosetta-api.org/docs/node_deployment.html#build-anywhere) requirement.

## `adjust_config.py`

This script is used to tailor the default Observer configuration. More precisely, it alters the files `config.toml` and `prefs.toml` accordingly and adjusts settings related to `DbLookupExtensions`, `Antiflood` etc.

## `entrypoint_observer.sh`

This script should be used as the _entrypoint_ of the Observer image.

Invocation example:

```
/elrond/entrypoint_observer.sh network=devnet ${NODE_CLI_ARGUMENTS}
```

Above, note the marker `network=devnet`. This marker selects the appropriate node configuration. For mainnet, `network=mainnet` should be used.

## Notable references
 - [Docker: How to execute a shell command before the ENTRYPOINT](https://stackoverflow.com/a/41518225)
