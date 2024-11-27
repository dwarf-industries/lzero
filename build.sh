#!/bin/bash

rm -rf output/ go_contracts/

mkdir -p go_contracts

for contract in contracts/*.sol; do
    contract_name=$(basename "$contract" .sol)
    solc --base-path . --abi --bin "$contract" -o output
    abigen --bin="output/$contract_name.bin" --abi="output/$contract_name.abi" --pkg="$contract_name" --out="go_contracts/$contract_name.go"
done
