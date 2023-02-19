import { Location } from "@angular/common";
import { HttpClient, HttpHeaders } from "@angular/common/http";
import { AfterViewInit, Component, OnInit, ViewChild } from "@angular/core";
import { __core_private_testing_placeholder__ } from "@angular/core/testing";
import { ActivatedRoute, Router } from "@angular/router";
import { ErrorService } from "src/app/services/error/error.service";
import { environment } from "src/environments/environment";
import Web3 from "web3";
import { LoadingService } from "../../../services/loading/loading.service";
import { PoolsResponse, PoolsService } from "../pools.service";
import { map } from "rxjs/operators";
import { MatTableDataSourcePaginator } from "@angular/material/table";



@Component({
  selector: 'pools-list',
  templateUrl: './pools-list.component.html',
  styleUrls: [ './pools-list.component.scss' ]
})
export class PoolsListComponent implements AfterViewInit, OnInit  {

  // TODO FIX POOLS LIST TO show all blockchains where the 
  // contract is deployed and show corresponding link icon for 
  // the blockchain

  displayedColumns: string[] = [
    'poolId',
    'asset1Name',
    'asset2Name',
    'currentPriceFor1Asset1InAsset2',
    'asset1' ,
    'asset1Decimals',
    'asset2',
    'asset2Decimals',
    'asset1Amount', 
    'asset2Amount',
    'asset2InitiallyAskedAmount',
    'maxBuyAsset1PercentPerTransaction',
    'constantProduct',
    'isConstantPrice',
    'initialAsset1Amount',
    'poolOwner',
    'isLocked',
    'isEmpty'
  ];
  columnsToDisplay: string[] = this.displayedColumns.slice();

  dataSource: any[] = [];

    constructor(
      private router: Router,
      private activatedRoute: ActivatedRoute,
      private poolsService: PoolsService,
    ){
      this.activatedRoute.params
      .subscribe((params) => {
        if (params && params.blockchain) {
          // this.selectedBlockchainIndex = 0;
          for (let i = 0; i < this.blockchains.length; ++i) {
            if (this.blockchains[i].paramName === params.blockchain) {
              this.selectedBlockchainIndex = i;
              break;
            }
          }
        }
      });
    }

    @ViewChild('paginator') paginator: MatTableDataSourcePaginator | undefined = undefined;

    totalNumberOfPools = 0;

    ngAfterViewInit( ) {
      this.activatedRoute.params
      .subscribe((params) => {
        if (params && params.blockchain) {
          // this.selectedBlockchainIndex = 0;
          for (let i = 0; i < this.blockchains.length; ++i) {
            if (this.blockchains[i].paramName === params.blockchain) {
              this.selectedBlockchainIndex = i;
              break;
            }
          }

          let blockchain = this.blockchains[this.selectedBlockchainIndex].paramName;
          this.getPools(0, this.paginator?.pageSize || 10, blockchain);

          this.paginator?.page.subscribe(page => {
             let start = page.pageIndex * page.pageSize;
             let end = start + page.pageSize;
             this.getPools(start, end, blockchain);
          });
        }
      });
    }

    ngOnInit(): void {
      let blockchain = this.blockchains[this.selectedBlockchainIndex].paramName;
      this.getPools(0, this.paginator?.pageSize || 10, blockchain);
    }

    getPools(start: number, end: number, blockchain: string) {
      this.poolsService.getPools(
        start,
        end, 
        blockchain,
      ).subscribe((pools: PoolsResponse) => {
        this.dataSource = pools.poolsOnPage;
        this.totalNumberOfPools = pools.totalNumberOfPools;
      }, (error: any) => {
        this.dataSource = [];
        this.totalNumberOfPools = 0;
      });
    }

    rowClicked(row: any) {
      console.log("Clicked row: " + row);
    }

    public blockchains = [
      // {
      //   name: 'Ethereum Mainnet',
      //   icon: 'ethereum.png',
      //   scanIcon: 'etherscan.png',
      //   scanUrl: 'https://etherscan.io/address/0x80004035cc793678290a7e879b77c6cba3730008',
      //   paramName: 'eth',
      // },
      /*
      {
        name: 'Binance Smart Chain',
        icon: 'bscchain.png',
        scanIcon: 'bscscan.png',
        scanUrl: 'https://bscscan.com/address/0x888d478f3a26216b0d79bad47daf39c7018b0888',
        paramName: 'bsc',
      },
      {
        name: 'Polygon Mainnet',
        icon: 'polygonscan.png',
        scanIcon: 'polygonscan.png',
        scanUrl: 'https://polygonscan.com/address/0x888d478f3a26216b0d79bad47daf39c7018b0888',
        paramName: 'polygon',
      },
      {
        name: 'Avalanche Network C-Chain',
        icon: 'snowtrace.png',
        scanIcon: 'snowtrace.png',
        scanUrl: 'https://snowtrace.io/address/0x888d478f3a26216b0d79bad47daf39c7018b0888',
        paramName: 'avalanche',
      },
      {
        name: 'BitTorrent Chain',
        icon: 'bttcscan.png',
        scanIcon: 'bttcscan.png',
        scanUrl: 'https://bttcscan.com/address/0x888d478f3a26216b0d79bad47daf39c7018b0888',
        paramName: 'bttc',
      },
      {
        name: 'Fantom Opera',
        icon: 'ftmscan.png',
        scanIcon: 'ftmscan.png',
        scanUrl: 'https://ftmscan.com/address/0x888d478f3a26216b0d79bad47daf39c7018b0888',
        paramName: 'fantom',
      },
      {
        name: 'Optimism',
        icon: 'optimism.png',
        scanIcon: 'optimism.png',
        scanUrl: 'https://optimistic.etherscan.io/address/0x888d478f3a26216b0d79bad47daf39c7018b0888',
        paramName: 'optimism',
      },
      {
        name: 'Gnosis Chain',
        icon: 'gnosis.png',
        scanIcon: 'gnosis.png',
        scanUrl: 'https://gnosisscan.io/address/0x888d478f3a26216b0d79bad47daf39c7018b0888',
        paramName: 'gnosis',
      },
      */
      {
        name: 'Sepolia Testnet',
        icon: 'sepolia.png',
        scanIcon: 'sepolia.png',
        scanUrl: 'https://sepolia.etherscan.io/address/0x80004035cc793678290a7e879b77c6cba3730008',
        paramName: 'sepolia',
      },
    ];
    
    selectedBlockchainIndex: number = 0;

    selectedBlockchainChanged(selectedBlockchainIndex: number) {
      console.log('selected blockchain changed to: ' + 
          JSON.stringify(this.blockchains[selectedBlockchainIndex]));
      this.router.navigate([
          'pools', 
          this.blockchains[selectedBlockchainIndex].paramName
      ]);
    }
}

