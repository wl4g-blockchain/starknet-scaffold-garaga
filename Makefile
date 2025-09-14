install-bun:
	curl -fsSL https://bun.sh/install | bash

install-noir:
	curl -L https://raw.githubusercontent.com/noir-lang/noirup/refs/heads/main/install | bash
	noirup --version 1.0.0-beta.6

install-barretenberg:
	curl -L https://raw.githubusercontent.com/AztecProtocol/aztec-packages/refs/heads/master/barretenberg/bbup/install | bash
	bbup --version 0.86.0-starknet.1

install-starknet:
	curl --proto '=https' --tlsv1.2 -sSf https://sh.starkup.dev | sh

install-devnet:
	asdf plugin add starknet-devnet
	asdf install starknet-devnet 0.4.2

install-garaga:
	pip install garaga==0.18.1

install-app-deps:
	cd app && bun install

devnet:
	starknet-devnet --accounts=2 --seed=0 --initial-balance=100000000000000000000000

accounts-file:
	# Must be 'alpah-sepolia' and see:https://github.com/foundry-rs/starknet-foundry/blob/437d128b4f54847666ea8021530d237f6bf47866/crates/sncast/src/lib.rs#L237-L238
	curl -s http://localhost:5050/predeployed_accounts | jq '{"alpha-sepolia": {"devnet0": {address: .[0].address, private_key: .[0].private_key, public_key: .[0].public_key, class_hash: "0xe2eb8f5672af4e6a4e8a8f1b44989685e668489b0a25437733756c5a34a1d6", deployed: true, legacy: false, salt: "0x14", type: "open_zeppelin"}}}' > ./contracts/accounts.json

build-circuit:
	cd circuit && nargo build

exec-circuit:
	cd circuit && nargo execute witness

prove-circuit:
	bb prove --scheme ultra_honk --oracle_hash starknet -b ./circuit/target/circuit.json -w ./circuit/target/witness.gz -o ./circuit/target

gen-vk:
	bb write_vk --scheme ultra_honk --oracle_hash starknet -b ./circuit/target/circuit.json -o ./circuit/target

gen-verifier:
	cd contracts && garaga gen --system ultra_starknet_honk --vk ../circuit/target/vk --project-name verifier

gen-verifier-starknet-zk:
	cd contracts && garaga gen --system ultra_starknet_zk_honk --vk ../circuit/target/vk --project-name verifier

gen-verifier-keccak-zk:
	cd contracts && garaga gen --system ultra_keccak_zk_honk --vk ../circuit/target/vk --project-name verifier

build-verifier:
	cd contracts/verifier && scarb build

declare-verifier:
	cd contracts && sncast --profile devnet declare --contract-name UltraStarknetHonkVerifier

declare-verifier-starknet-zk:
	cd contracts && sncast --profile devnet declare --contract-name UltraStarknetZKHonkVerifier

declare-verifier-keccak-zk:
	cd contracts && sncast --profile devnet declare --contract-name UltraKeccakZKHonkVerifier

declare-verifier-sepolia:
	cd contracts && sncast --profile sepolia declare --contract-name UltraStarknetHonkVerifier

# Note: Only barretenberg-v1.2.1 was supported Starknet ZK mode to proof.
# https://github.com/wl4g-blockchain/zkp-barretenberg/blob/v1.2.1/barretenberg/cpp/src/barretenberg/dsl/acir_proofs/c_bind.cpp#L216-L217
declare-verifier-sepolia-starknet-zk:
	cd contracts && sncast --profile sepolia declare --contract-name UltraStarknetZKHonkVerifier

declare-verifier-sepolia-keccak-zk:
	cd contracts && sncast --profile sepolia declare --contract-name UltraKeccakZKHonkVerifier

deploy-verifier:
	# TODO: Should be using the class hash from the return result of the `make declare-verifier` step
	cd contracts && sncast --profile devnet deploy --salt 0xaabb --class-hash 0x04789fd76a79b3e7441bef841e497491d7cb3eced37b6a0d623b337def582b2c

deploy-verifier-sepolia:
	# TODO: Should be using the class hash from the return result of the `make declare-verifier-sepolia` step
	cd contracts && sncast --profile devnet deploy --salt 0xaabb --class-hash 0x004d13e14caa3b225b07595e7edcade77ce849e30ee7908bf4b2e4446d652ebf

artifacts:
	cp ./circuit/target/circuit.json ./app/src/assets/circuit.json
	cp ./circuit/target/vk ./app/src/assets/vk.bin
	cp ./contracts/target/release/verifier_UltraStarknetHonkVerifier.contract_class.json ./app/src/assets/verifier.json

artifacts-starknet-zk:
	cp ./circuit/target/circuit.json ./app/src/assets/circuit.json
	cp ./circuit/target/vk ./app/src/assets/vk.bin
	cp ./contracts/target/release/verifier_UltraStarknetZKHonkVerifier.contract_class.json ./app/src/assets/verifier.json

artifacts-keccak-zk:
	cp ./circuit/target/circuit.json ./app/src/assets/circuit.json
	cp ./circuit/target/vk ./app/src/assets/vk.bin
	cp ./contracts/target/release/verifier_UltraKeccakZKHonkVerifier.contract_class.json ./app/src/assets/verifier.json

run-app:
	cd app && bun run dev
