rm -rf output/ && solc --base-path . --abi --bin contracts/Register.sol -o output && abigen --bin=output/Register.bin --abi=output/Register.abi --pkg=register --out=Register.go && solc --base-path . --abi --bin contracts/Ledger.sol -o output && abigen --bin=output/PaymentLedger.bin --abi=output/PaymentLedger.abi --pkg=ledger --out=Ledger.go

