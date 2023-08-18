include .env

.PHONY: help build fmt testLocal testSepolia deploySepolia deploy fund withdraw

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make fund [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""

build :; forge build
fmt :; forge fmt
testLocal :; forge test

testSepolia :; forge test --fork-url $(SEPOLIA_FORK_URL)

deploySepolia :
	forge script script/DeployFundMe.s.sol --fork-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY_MM_FP) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvvv

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(PRIVATE_KEY_ANVIL_N1) --broadcast

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY_MM_FP) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

deploy:
	@forge script script/DeployFundMe.s.sol:DeployFundMe $(NETWORK_ARGS)

fund:
	@forge script script/Interactions.s.sol:FundFundMe $(NETWORK_ARGS)

withdraw:
	@forge script script/Interactions.s.sol:WithdrawFundMe $(NETWORK_ARGS)