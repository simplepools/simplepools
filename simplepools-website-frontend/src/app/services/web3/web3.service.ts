import { Injectable } from "@angular/core";
import { Location } from "@angular/common";
import { HttpClient, HttpHeaders } from "@angular/common/http";
import { Component, OnInit, ViewChild, AfterViewInit } from "@angular/core";
import { __core_private_testing_placeholder__ } from "@angular/core/testing";
import { ActivatedRoute, ActivationEnd, ChildrenOutletContexts, NavigationEnd, Route, Router, RouterOutlet } from "@angular/router";
import { ErrorService } from "src/app/services/error/error.service";
import { environment } from "src/environments/environment";
import Web3 from "web3";
import { LoadingService } from "../../services/loading/loading.service";
import { slideInAnimation } from "src/app/animations";

import { configureChains, createClient, fetchSigner, getProvider } from '@wagmi/core'
import { mainnet, bsc, polygon, avalanche, fantom, optimism, gnosis, sepolia } from '@wagmi/core/chains'
import { EthereumClient, modalConnectors, walletConnectProvider } from '@web3modal/ethereum'
import { Web3Modal } from '@web3modal/html'
import { of, Subject } from "rxjs";
import { fetchEnsName } from '@wagmi/core'
import { signMessage } from '@wagmi/core'
import { prepareWriteContract, writeContract, readContract, fetchBalance, getContract } from '@wagmi/core'

import SIMPLE_POOLS_ABI from './spabi.json';
import IERC20_ABI from './ierc20abi.json';

export const BLOCKCHAIN_PARAM_NAME = 'blockchain';

export const CONTRACT_TAX_ETH = 0.001;

// 1. Define constants
const WALLET_CONNECT_PROJECT_ID = '0931fefaa37b434ee74d3f9f287bb2d8'; // simplepools walletconnect project id
const CHAINS = [mainnet, bsc, polygon, /*avalanche,*/ /*fantom,*/ /*optimism, */gnosis, sepolia];

// 2. Configure wagmi client
const { provider } = configureChains(CHAINS, [walletConnectProvider({ projectId: WALLET_CONNECT_PROJECT_ID })]);
const WAGMI_CLIENT = createClient({
  autoConnect: false,
  connectors: [...modalConnectors({ appName: 'web3Modal', chains: CHAINS })],
  provider
});

const SIMPLE_POOLS_CONTRACT_ADDRESS = '0x80004035cc793678290a7e879b77c6cba3730008';
  
import { getAccount } from '@wagmi/core'
import { ContractFactory, ethers, Signer } from "ethers";
import { webworker } from "src/app/app.component";
import { CookieService } from "ngx-cookie-service";

// 3. Create ethereum and modal clients
export const ETHEREUM_CLIENT = new EthereumClient(WAGMI_CLIENT, CHAINS);
export const WEB3_MODAL = new Web3Modal(
  {
    projectId: WALLET_CONNECT_PROJECT_ID,
    // walletImages: {
    //   safe: 'https://pbs.twimg.com/profile_images/1566773491764023297/IvmCdGnM_400x400.jpg'
    // },
    defaultChain: mainnet,
    themeMode: "dark",
    themeColor: "orange",
    themeBackground: "themeColor"
  },
  ETHEREUM_CLIENT
);

export const WEB3_MODAL_STATE_SUBJECT: Subject<any> = new Subject();

WEB3_MODAL.subscribeModal((x) => {
  WEB3_MODAL_STATE_SUBJECT.next(x);
});

export const CHAIN_CHANGED_SUBJECT = new Subject<any>();

export const CHAINS_METADATA = [
  {
    name: 'Ethereum',
    icon: 'ethereum.png',
    scanIcon: 'etherscan.png',
    scanUrl: 'https://etherscan.io/address/0x80004035cc793678290a7e879b77c6cba3730008',
    paramName: 'eth',
    chain: mainnet
  },
  {
    name: 'BNB Smart Chain',
    icon: 'bscchain.png',
    scanIcon: 'bscscan.png',
    scanUrl: 'https://bscscan.com/address/0x80004035cc793678290a7e879b77c6cba3730008',
    paramName: 'bsc',
    chain: bsc
  },
  {
    name: 'Polygon',
    icon: 'polygonscan.png',
    scanIcon: 'polygonscan.png',
    scanUrl: 'https://polygonscan.com/address/0x80004035cc793678290a7e879b77c6cba3730008',
    paramName: 'polygon',
    chain: polygon
  },
  // {
  //   name: 'Avalanche',
  //   icon: 'snowtrace.png',
  //   scanIcon: 'snowtrace.png',
  //   scanUrl: 'https://snowtrace.io/address/0x80004035cc793678290a7e879b77c6cba3730008',
  //   paramName: 'avalanche',
  //   chain: avalanche
  // },
  // {
  //   name: 'BitTorrent Chain',
  //   icon: 'bttcscan.png',
  //   scanIcon: 'bttcscan.png',
  //   scanUrl: 'https://bttcscan.com/address/0x80004035cc793678290a7e879b77c6cba3730008',
  //   paramName: 'bttc',
  // },
  // {
  //   name: 'Fantom',
  //   icon: 'ftmscan.png',
  //   scanIcon: 'ftmscan.png',
  //   scanUrl: 'https://ftmscan.com/address/0x80004035cc793678290a7e879b77c6cba3730008',
  //   paramName: 'fantom',
  //   chain: fantom
  // },
  // {
  //   name: 'Optimism',
  //   icon: 'optimism.png',
  //   scanIcon: 'optimism.png',
  //   scanUrl: 'https://optimistic.etherscan.io/address/0x80004035cc793678290a7e879b77c6cba3730008',
  //   paramName: 'optimism',
  //   chain: optimism,
  // },
  {
    name: 'Gnosis',
    icon: 'gnosis.png',
    scanIcon: 'gnosis.png',
    scanUrl: 'https://gnosisscan.io/address/0x80004035cc793678290a7e879b77c6cba3730008',
    paramName: 'gnosis',
    chain: gnosis,
  },
  {
    name: 'Sepolia',
    icon: 'sepolia.png',
    scanIcon: 'sepolia.png',
    scanUrl: 'https://sepolia.etherscan.io/address/0x80004035cc793678290a7e879b77c6cba3730008',
    paramName: 'sepolia',
    chain: sepolia
  },
];

export const CHAIN_HOLDER = [CHAINS_METADATA[0].paramName];

CHAIN_CHANGED_SUBJECT.subscribe(chain => {
  let chainIdx = 0;
  for (let i = 0; i < CHAINS_METADATA.length; ++i) {
    if (chain === CHAINS_METADATA[i].name || chain === CHAINS_METADATA[i].paramName 
            || chain === CHAINS_METADATA[i].chain.id) {
      chainIdx = i;
      break;
    }
  }

  // If connected switch 
  WEB3_MODAL.setDefaultChain(CHAINS_METADATA[chainIdx].chain);
  ETHEREUM_CLIENT.switchNetwork({ chainId: CHAINS_METADATA[chainIdx].chain.id })
      .catch(error => {
        console.error(error);
        ETHEREUM_CLIENT.disconnect();
  });
});


export let COOKIES_SERVICE: CookieService;

@Injectable({
    providedIn: 'root',
})
export class Web3Service {

    constructor(
      public loading: LoadingService,
      private localCookies: CookieService,
      public router: Router
    ) {
      router.events.subscribe(e => {
        if (e instanceof ActivationEnd) {
            const blockchainParam = e.snapshot.paramMap.get(BLOCKCHAIN_PARAM_NAME) || CHAIN_HOLDER[0];
            if (blockchainParam !== CHAIN_HOLDER[0]) {
              CHAIN_HOLDER[0] = blockchainParam;
              CHAIN_CHANGED_SUBJECT.next(blockchainParam);
            }
        }
      });

      COOKIES_SERVICE = localCookies;
      let blockchain = COOKIES_SERVICE.get(BLOCKCHAIN_PARAM_NAME);
      console.log('blockchain from cookies: ' + blockchain);
      if (!blockchain) {
        COOKIES_SERVICE.set(BLOCKCHAIN_PARAM_NAME, CHAIN_HOLDER[0]);
      }
      for (let connector of WAGMI_CLIENT.connectors) {
        let onAccountsChangedFunc = connector['onAccountsChanged'];
        connector['onAccountsChanged'] = (accounts) => {
          onAccountsChangedFunc(accounts);
          console.log('accounts changed: ' + accounts);
        };
        let onChainChangedFunc = connector['onChainChanged'];
        connector['onChainChanged'] = (chain) => {
          onChainChangedFunc(chain);
          console.log('chain changed: ' + chain);
          CHAIN_CHANGED_SUBJECT.next(Number.parseInt(''+chain, 16));
        };
      }
      webworker.onmessage = (data) => {
        this.onWebworkerMessage(this as any, data);
      } 
    }

    async onWebworkerMessage(obj: any, data: any) {
      console.log(`page got message: ${data}`);
      const compiled = JSON.parse(data.data.compilation);

      const contract = compiled.contracts['storage.sol'][data.data.contractName];

      console.log(contract);
      const contractFactory = new ContractFactory(
        contract.abi, contract.evm.bytecode,        
        (await fetchSigner() as Signer)
      );
      console.log(contractFactory);
      const dep = await contractFactory.deploy();
      console.log(dep);
      const res = await dep.deployed();
      console.log(res);
      obj.contractAddressSubject.next(res.address);
      obj.loading.isLoading.next(false);
    }
    // TODO add listener when wallet is connected to re-get balance

    getAddress() {
      console.log(WAGMI_CLIENT);
      return getAccount().address;
    }

    async getBalance(isNative: boolean, contractAddress: any): Promise<string> {
      if (isNative) {
        const balance = await fetchBalance({
          address: this.getAddress() as any,
        })
        return balance.formatted;
      } else {
        const data = await readContract({
          address: contractAddress,
          abi: IERC20_ABI,
          functionName: 'balanceOf',
          args: [this.getAddress()]
        });
        console.log(data);
        return ethers.utils.formatEther(data as any);
      }
    }

    async approve(
      assetContractAddress: any
    ): Promise<boolean> {
      let approveConfig = await prepareWriteContract({
        address: assetContractAddress,
        abi: IERC20_ABI,
        functionName: 'increaseAllowance',
        args: [SIMPLE_POOLS_CONTRACT_ADDRESS, ethers.utils.parseEther('999999999999999999')]
      });
      const data = await writeContract(approveConfig);
      console.log(data);
      const tmp = await data.wait(1);
      console.log(tmp);
      return true;
    } 

    async isApproved(
      assetContractAddress: any,
      amountEth: string
    ): Promise<boolean> {
      let approvedAmount: any = await readContract({
        address: assetContractAddress,
        abi: IERC20_ABI,
        functionName: 'allowance',
        args: [this.getAddress(), SIMPLE_POOLS_CONTRACT_ADDRESS]
      });
      const amountRequired = ethers.utils.parseEther(amountEth);
      return approvedAmount.gte(amountRequired);
    }

    async createPool(
      asset1: string,
      isAsset1Native: boolean,
      asset2: string,
      isAsset2Native: boolean,
      asset1Amount: number,
      asset2InitiallyAskedAmount: number,
      maxBuyAsset1PercentPerTransaction: number,
      isConstantPrice: boolean,
    ): Promise<string> {
      if (!isAsset1Native) {
        let isApproved = await this.isApproved(asset1, ''+asset1Amount);
        if (!isApproved) {
          return 'approveRequired';
        }
      }
      let a1amount = ethers.utils.parseEther(''+asset1Amount);
      let a2iaAmount = ethers.utils.parseEther(''+asset2InitiallyAskedAmount);
      let config: any;
      const txValue = ethers.utils.parseEther('' + CONTRACT_TAX_ETH);
      try {
        config = await prepareWriteContract({
          address: SIMPLE_POOLS_CONTRACT_ADDRESS,
          abi: SIMPLE_POOLS_ABI,
          functionName: 'createPool',
          args: [
            this.getAddress(),
            isAsset1Native,
            asset1,
            isAsset2Native,
            asset2,
            a1amount,
            a2iaAmount,
            maxBuyAsset1PercentPerTransaction,
            isConstantPrice
          ],
          overrides: {
            value: txValue,
          }
        });
        console.log(config);
      } catch (e: any) {
        console.error(e);
        if (e.reason.indexOf('allowance') !== -1) {
          return 'approveRequired';
        }
      }
      const data = await writeContract(config);
      console.log(data);
      const tmp = await data.wait(1);
      console.log(tmp);
      return '';
    }

    async exchange(
      personExecuting: any,
      pid: number,
      isSellingNative: boolean,
      isBuyingA1: boolean,
      amount: any,
    ): Promise<string> {
      const sellValue = ethers.utils.parseEther(''+amount);
      const txValue = 
          isSellingNative 
            ? ethers.utils.parseEther(''+(CONTRACT_TAX_ETH + amount))
            : ethers.utils.parseEther(''+CONTRACT_TAX_ETH);
      let config: any;
      try {
          config = await prepareWriteContract({
            address: SIMPLE_POOLS_CONTRACT_ADDRESS,
            abi: SIMPLE_POOLS_ABI,
            functionName: 'exchangeAsset',
            args: [personExecuting, pid, isBuyingA1, sellValue, 0],
            overrides: {
              value: txValue,
            }
        });
      } catch (e: any) {
        if (e.reason.indexOf('allowance') !== -1) {
          return 'approveRequired';
        }
        console.log(e);
        return e.reason;
      }
      const data = await writeContract(config);
      console.log(data);
      const tmp = await data.wait(1);
      console.log(tmp);
      return '';
    }

    contractAddressSubject: Subject<string> | undefined;

    async deploy(data: any) {

      this.contractAddressSubject = data.contractAddressSubject;
      webworker.postMessage({
        source: data.assetCode,
        contractName: data.contractName,
      });
    }

    async connect() {
        this.loading.isLoading.next(true);
        const signature = await signMessage({
            message: 'Toshko',
        });
        this.loading.isLoading.next(false);
        console.log("Signature: " + signature);
    }
}