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
import { CHAINS_METADATA, CHAIN_CHANGED_SUBJECT, CHAIN_HOLDER, WEB3_MODAL } from "src/app/services/web3/web3.service";



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
    }

    @ViewChild('paginator') paginator: MatTableDataSourcePaginator | undefined = undefined;

    totalNumberOfPools = 0;

    ngAfterViewInit( ) {
      
    }

    ngOnInit(): void {
      this.getPools(0, this.paginator?.pageSize || 10, CHAIN_HOLDER[0]);

      this.paginator?.page.subscribe(page => {
        let start = page.pageIndex * page.pageSize;
        let end = start + page.pageSize;
        this.getPools(start, end, CHAIN_HOLDER[0]);
      });

      CHAIN_CHANGED_SUBJECT.subscribe(chain => {
        this.getPools(0, this.paginator?.pageSize || 10, CHAIN_HOLDER[0]);
      });
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
}

