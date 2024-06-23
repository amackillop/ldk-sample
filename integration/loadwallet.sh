#!/usr/bin/env bash
set -xeo pipefail

# Load a wallet
bitcoin-cli -regtest -datadir=./integration/bitcoind loadwallet $1