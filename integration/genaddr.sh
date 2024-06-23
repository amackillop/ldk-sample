#!/usr/bin/env bash
set -xeo pipefail

# Generate a new bitcoin address
bitcoin-cli -regtest -datadir=./integration/bitcoind getnewaddress


