import sys
from argparse import ArgumentParser
from typing import List

import toml

"""
python3 ./docker/adjust_config.py --mode=main --file=config.toml
python3 ./docker/adjust_config.py --mode=prefs --file=prefs.toml
"""

MODE_MAIN = "main"
MODE_PREFS = "prefs"
MODES = [MODE_MAIN, MODE_PREFS]


def main(cli_args: List[str]):
    parser = ArgumentParser()
    parser.add_argument("--mode", choices=MODES, required=True)
    parser.add_argument("--file", required=True)
    parser.add_argument("--api-simultaneous-requests", type=int, default=16384)

    parsed_args = parser.parse_args(cli_args)
    mode = parsed_args.mode
    file = parsed_args.file
    api_simultaneous_requests = parsed_args.api_simultaneous_requests

    data = toml.load(file)

    if mode == MODE_MAIN:
        data["GeneralSettings"]["StartInEpochEnabled"] = False
        data["DbLookupExtensions"]["Enabled"] = True
        data["StateTriesConfig"]["AccountsStatePruningEnabled"] = False
        data["StoragePruning"]["ObserverCleanOldEpochsData"] = False
        data["StoragePruning"]["AccountsTrieCleanOldEpochsData"] = False
        data["Antiflood"]["WebServer"]["SimultaneousRequests"] = api_simultaneous_requests
    elif mode == MODE_PREFS:
        data["Preferences"]["FullArchive"] = True
    else:
        raise Exception(f"Unknown mode: {mode}")

    with open(file, "w") as f:
        toml.dump(data, f)

    print(f"Configuration adjusted: mode = {mode}, file = {file}")


if __name__ == "__main__":
    main(sys.argv[1:])
