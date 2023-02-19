import { Injectable } from "@angular/core";
import { Location } from "@angular/common";
import { HttpClient, HttpHeaders } from "@angular/common/http";
import { Component, OnInit, ViewChild, AfterViewInit } from "@angular/core";
import { __core_private_testing_placeholder__ } from "@angular/core/testing";
import { ActivatedRoute, ChildrenOutletContexts, Route, Router, RouterOutlet } from "@angular/router";
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

import spabi from './spabi.json';
import ierc20abi from './ierc20abi.json';
import spbin from './spbin.json';

// var wrapper = require('solc/wrapper');
// var solc = wrapper(wrapper.Module);


export const contractTax = 0.001;

// 1. Define constants
const projectId = '0931fefaa37b434ee74d3f9f287bb2d8'; // simplepools walletconnect project id
const chains = [mainnet, bsc, polygon, avalanche, fantom, optimism, gnosis, sepolia];

// 2. Configure wagmi client
const { provider } = configureChains(chains, [walletConnectProvider({ projectId })]);
const wagmiClient = createClient({
  autoConnect: true,
  connectors: [...modalConnectors({ appName: 'web3Modal', chains })],
  provider
});


const simplePoolsContractAddress = '0x80004035cc793678290a7e879b77c6cba3730008';
  
import { getAccount } from '@wagmi/core'
import { ContractFactory, ethers, Signer } from "ethers";
import { webworker } from "src/app/app.component";


// 3. Create ethereum and modal clients
const ethereumClient = new EthereumClient(wagmiClient, chains);
export const web3Modal = new Web3Modal(
  {
    projectId,
    // walletImages: {
    //   safe: 'https://pbs.twimg.com/profile_images/1566773491764023297/IvmCdGnM_400x400.jpg'
    // },
    defaultChain: mainnet,
    themeMode: "dark",
    themeColor: "orange",
    themeBackground: "themeColor"
  },
  ethereumClient
);


@Injectable({
    providedIn: 'root',
})
export class Web3Service {

    constructor(public loading: LoadingService) {
        // this.signClientPromise = SignClient.init({
        //     projectId: projectId,
        //     // optional parameters
        //     metadata: {
        //       name: "Simple Pools",
        //       description: "DeFi made simple",
        //       url: "#",
        //       icons: ["https://walletconnect.com/walletconnect-logo.png"],
        //     },
        // });
        for (let connector of wagmiClient.connectors) {
          let onAccountsChangedFunc = connector['onAccountsChanged'];
          connector['onAccountsChanged'] = (accounts) => {
            onAccountsChangedFunc(accounts);
            console.log('accounts changed: ' + accounts);
          };
          let onChainChangedFunc = connector['onChainChanged'];
          connector['onChainChanged'] = (chain) => {
            onChainChangedFunc(chain);
            console.log('chain changed: ' + chain);
          };
          // connector.on('chainChanged' as any, chain => {
          //   console.log("Chain changed: " + chain);
          // });
        }
        webworker.onmessage = (data) => {
          this.onWebworkerMessage(this as any, data);
        } 
    }

    async onWebworkerMessage(obj: any, data: any) {
      console.log(`page got message: ${data}`);
            // console.log(solc);
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
      console.log(wagmiClient);
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
          abi: ierc20abi,
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
        abi: ierc20abi,
        functionName: 'increaseAllowance',
        args: [simplePoolsContractAddress, ethers.utils.parseEther('999999999999999999')]
      });
      const data = await writeContract(approveConfig);
      console.log(data);
      const tmp = await data.wait(1);
      console.log(tmp);
      return true;
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
      let a1amount = ethers.utils.parseEther(''+asset1Amount);
      let a2iaAmount = ethers.utils.parseEther(''+asset2InitiallyAskedAmount);
      let config: any;
      const txValue = ethers.utils.parseEther('' + contractTax);
      try {
        config = await prepareWriteContract({
          address: simplePoolsContractAddress,
          abi: spabi,
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
            ? ethers.utils.parseEther(''+(contractTax + amount))
            : ethers.utils.parseEther(''+contractTax);
      let config: any;
      try {
          config = await prepareWriteContract({
            address: simplePoolsContractAddress,
            abi: spabi,
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
      // console.log(solc);

      // const sp = new ContractFactory(
      //   spabi, spbin,        
      //   (await fetchSigner() as Signer)
      // );
      // console.log(sp);
      // const dep = await sp.deploy();
      // console.log(dep);
      // const res = await dep.deployed();
      // console.log(res);
    }

    // signClientPromise: Promise<SignClient>;

    async connect() {
        this.loading.isLoading.next(true);
        const signature = await signMessage({
            message: 'Toshko',
        });
        this.loading.isLoading.next(false);
        console.log("Signature: " + signature);
        // const signClient = await this.signClientPromise;
        // signClient.on("session_event", (event) => {
        //     console.log('session event' + event);
        //     // Handle session events, such as "chainChanged", "accountsChanged", etc.
        //   });
          
        //   signClient.on("session_update", ( params ) => {
        //     console.log('session event' + params);
        //   });
          
        //   signClient.on("session_delete", (params) => {
        //     console.log('session event' + params);
        //     // Session was deleted -> reset the dapp state, clean up from user session, etc.
        //   });
        //   const { uri, approval } = await signClient.connect({
        //     // Optionally: pass a known prior pairing (e.g. from `signClient.core.pairing.getPairings()`) to skip the `uri` step.
            
        //     // Provide the namespaces and chains (e.g. `eip155` for EVM-based chains) we want to use in this session.
        //     requiredNamespaces: {
        //       eip155: {
        //         methods: [
        //           "eth_sendTransaction",
        //           "eth_signTransaction",
        //           "eth_sign",
        //           "personal_sign",
        //           "eth_signTypedData",
        //         ],
        //         chains: ["eip155:1"],
        //         events: ["chainChanged", "accountsChanged"],
        //       },
        //     },
        //   });


        // //   const session = await approval();
        // //   console.log(session);
        
        // const result = await signClient.request({
        //     topic: 'asdf',
        //     chainId: "eip155:1",
        //     request: {
        //       method: "personal_sign",
        //       params: [
        //         "0x1d85568eEAbad713fBB5293B45ea066e552A90De",
        //         "0x7468697320697320612074657374206d65737361676520746f206265207369676e6564",
        //       ],
        //     },
        // });
        // console.log(result);
    }
}