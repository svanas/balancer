[![GitHub release](https://img.shields.io/github/release/svanas/balancer)](https://github.com/svanas/balancer/releases/latest)
[![GitHub license](https://img.shields.io/github/license/svanas/balancer)](https://github.com/svanas/balancer/blob/main/LICENSE)
[![macOS](https://img.shields.io/badge/os-macOS-green)](https://github.com/svanas/balancer/releases/latest/download/macOS.zip)
[![Windows](https://img.shields.io/badge/os-Windows-green)](https://github.com/svanas/balancer/releases/latest/download/Windows.zip)

# balancer

Look Ma! No web browser. No JavaScript. No MetaMask.

## reason to be

This dapp is an implementation of the https://balancer.fi protocol in native code, made possible by [an awesome grant](https://twitter.com/BalancerGrants/status/1501558781330993153) from the [Balancer DAO](http://grants.balancer.community/).

## downloads

You can download this dapp for [Windows](https://github.com/svanas/balancer/releases/latest/download/Windows.zip) or [macOS](https://github.com/svanas/balancer/releases/latest/download/macOS.zip).

## networks

At the time of this writing, this dapp supports the following [EVM-compatible](https://chainlist.org) networks:
* [Ethereum](https://ethereum.org)
* [Sepolia](https://sepolia.etherscan.io)
* [Optimism](https://www.optimism.io)
* [Gnosis Chain](https://www.gnosischain.com)
* [Polygon](https://polygon.technology)
* [Base](https://base.org)
* [Arbitrum](https://arbitrum.io)

## compiling

1. Download and install [Delphi Community Edition](https://www.embarcadero.com/products/delphi/starter)
2. Clone [Delphereum](https://github.com/svanas/delphereum) and the [dependencies](https://github.com/svanas/delphereum#dependencies)
3. The compiler will stop at [infura.api.key](https://github.com/svanas/balancer/blob/main/infura.api.key)
4. Enter your [Infura](https://infura.io) API key
5. Should you decide to fork this repo, then do not commit your API key. Your API key is not to be shared.

## testing

1. Switch your MetaMask to the [Sepolia](https://sepolia.etherscan.io) test network
2. Navigate to https://sepoliafaucet.com
3. Paste your wallet address and press the `Send Me ETH` button
4. Wait for your transaction to get mined. Your wallet will get credited with 0.5 ETH
5. Navigate to https://app.balancer.fi/#/sepolia/faucet
6. Pick whatever token you will want to trade and press the `Drip` button
7. Wait for your transaction to get mined
8. Repeat step 6 and 7 for the other tokens you will want to trade
9. Launch balancer, paste your wallet address from MetaMask, select the Sepolia network

## disclaimer

This dapp is provided free of charge. There is no warranty and no independent audit has been or will be commissioned. You are encouraged to read the code and decide for yourself whether it is secure. The authors do not assume any responsibility for bugs, vulnerabilities, or any other technical defects. Use at your own risk.
