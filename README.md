[![GitHub release](https://img.shields.io/github/release/svanas/balancer)](https://github.com/svanas/balancer/releases/latest)
[![GitHub license](https://img.shields.io/github/license/svanas/balancer)](https://github.com/svanas/balancer/blob/main/LICENSE)
[![macOS](https://img.shields.io/badge/os-macOS-green)](https://github.com/svanas/balancer/releases/latest/download/macOS.zip)
[![Windows](https://img.shields.io/badge/os-Windows-green)](https://github.com/svanas/balancer/releases/latest/download/Windows.zip)

# balancer

Look Ma! No web browser. No JavaScript. No MetaMask.

## networks

At the time of this writing, balancer supports the following [EVM-compatible](https://chainlist.org) networks:
* [Ethereum](https://ethereum.org)
* [Kovan](https://kovan.etherscan.io)
* [Polygon](https://polygon.technology)
* [Arbitrum](https://arbitrum.io)

## compiling

1. Download and install [Delphi Community Edition](https://www.embarcadero.com/products/delphi/starter)
2. Clone [Delphereum](https://github.com/svanas/delphereum) and the [dependencies](https://github.com/svanas/delphereum#dependencies)
3. The compiler will stop at [infura.api.key](https://github.com/svanas/balancer/blob/main/infura.api.key)
4. Enter your [Infura](https://infura.io) API key
5. Should you decide to fork this repo, then do not commit your API key. Your API key is not to be shared.

## testing

1. Switch your MetaMask to the [Kovan](https://kovan.etherscan.io) test network
2. Navigate to https://faucets.chain.link
3. Check the box that reads `0.1 test ETH` and press the `Send Request` button
4. Wait for your transaction to get mined. Your wallet will get credited with 0.1 ETH
5. Navigate to https://balancer-faucet.on.fleek.co
6. Click an whatever token you will want to trade, paste your wallet address from MetaMask, enter the amount and press the `Get Tokens` button
7. Wait for your transaction to get mined
8. Repeat step 6 and 7 for the other tokens you will want to trade
9. Launch balancer, paste your wallet address from MetaMask, select the Kovan network

## disclaimer

This dapp is provided free of charge. There is no warranty and no independent audit has been or will be commissioned. You are encouraged to read the code and decide for yourself whether it is secure. The authors do not assume any responsibility for bugs, vulnerabilities, or any other technical defects. Use at your own risk.
