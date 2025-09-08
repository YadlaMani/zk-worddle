# zk-Worddle

zk-Worddle is a privacy-preserving word puzzle game leveraging zero-knowledge proofs (ZKPs) using Noir and Solidity smart contracts.

## Overview

- **Circuits**: Noir circuits define the ZK logic for verifying word guesses without revealing the solution.
- **Contracts**: Solidity smart contracts (Worddle.sol, Verifier.sol) handle on-chain verification and game state.
- **Proof Generation**: Proofs are generated off-chain and verified on-chain.

## Structure

- `circuits/`: Noir ZK circuit code and compiled artifacts
- `contracts/`: Solidity contracts, tests, and scripts
- `contracts/src/Worddle.sol`: Main game contract
- `contracts/src/Verifier.sol`: ZK proof verifier
- `contracts/js-scripts/`: Scripts for proof generation

## Usage

1. **Compile Circuits**: Use Nargo to build Noir circuits in `circuits/`.
2. **Deploy Contracts**: Deploy `Verifier.sol` and `Worddle.sol` to your EVM-compatible chain.
3. **Generate Proofs**: Use scripts in `contracts/js-scripts/` to generate ZK proofs for guesses.
4. **Verify On-Chain**: Submit proofs to the smart contract for verification and game progression.

## Requirements

- [Noir](https://noir-lang.org/) & Nargo
- [Foundry](https://getfoundry.sh/)
- Node.js (for scripts)

## Circuit Details

The main Noir circuit (`main.nr`) verifies a guess using the following inputs:

- **Private Inputs:**

  - `guess_hash` (`Field`): The hash of the user's guessed word. This value is kept private in the proof.

- **Public Inputs:**
  - `answer_double_hash` (`Field`): The double-hashed value of the correct answer, published on-chain for verification.
  - `address` (`Field`): The user's address, used for associating the proof with a player.

The circuit checks that the double hash of the guess matches the published answer hash and that the address is correctly formatted.

## License

MIT
