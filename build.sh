rm -rf output/ && solc --base-path . --abi --bin contracts/Register.sol -o output && abigen --bin=output/Register.bin --abi=output/Register.abi --pkg=register --out=Register.go
