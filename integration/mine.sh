#!/usr/bin/env bash
set -xeo pipefail

# Mine N blocks to an address
bitcoin-cli -regtest generatetoaddress 1 $1