import sys
from argparse import ArgumentParser
from typing import List

import toml

"""
python3 adjust_config.py --mode=main --file=config.toml
python3 adjust_config.py --mode=prefs --file=prefs.toml
"""

MODE_MAIN = "main"
MODE_PREFS = "prefs"
MODES = [MODE_MAIN, MODE_PREFS]


def main(cli_args: List[str]):
    parser = ArgumentParser()
    parser.add_argument("--mode", choices=MODES, required=True)
    parser.add_argument("--file", required=True)
    parser.add_argument("--api-simultaneous-requests", type=int, default=16384)
    parser.add_argument("--no-snapshots", action="store_true", default=False)
    parser.add_argument("--sync-process-time-milliseconds", type=int, default=12000)

    parsed_args = parser.parse_args(cli_args)
    mode = parsed_args.mode
    file = parsed_args.file
    api_simultaneous_requests = parsed_args.api_simultaneous_requests
    no_snapshots = parsed_args.no_snapshots
    snapshots_enabled = not no_snapshots
    sync_process_time_milliseconds = parsed_args.sync_process_time_milliseconds

    data = toml.load(file)

    if mode == MODE_MAIN:
        data["GeneralSettings"]["StartInEpochEnabled"] = False
        data["GeneralSettings"]["SyncProcessTimeInMillis"] = sync_process_time_milliseconds
        data["DbLookupExtensions"]["Enabled"] = True
        data["StateTriesConfig"]["AccountsStatePruningEnabled"] = False
        data["StateTriesConfig"]["SnapshotsEnabled"] = snapshots_enabled
        data["StoragePruning"]["ObserverCleanOldEpochsData"] = False
        data["StoragePruning"]["AccountsTrieCleanOldEpochsData"] = False
        data["WebServerAntiflood"]["SimultaneousRequests"] = api_simultaneous_requests
    elif mode == MODE_PREFS:
        data["Preferences"]["FullArchive"] = True
    else:
        raise Exception(f"Unknown mode: {mode}")

    with open(file, "w") as f:
        toml.dump(data, f)

    print(f"Configuration adjusted: mode = {mode}, file = {file}")


if __name__ == "__main__":
    main(sys.argv[1:])
