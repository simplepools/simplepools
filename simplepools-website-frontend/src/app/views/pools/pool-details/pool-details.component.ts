import { Location } from "@angular/common";
import { HttpClient, HttpHeaders } from "@angular/common/http";
import { Component, OnInit } from "@angular/core";
import { __core_private_testing_placeholder__ } from "@angular/core/testing";
import { ActivatedRoute, Route, Router } from "@angular/router";
import { ErrorService } from "src/app/services/error/error.service";
import { environment } from "src/environments/environment";
import Web3 from "web3";
import { LoadingService } from "../../../services/loading/loading.service";
import * as ethers from "ethers"
import { CHAIN_HOLDER, CONTRACT_TAX_ETH, Web3Service } from "src/app/services/web3/web3.service";


@Component({
  selector: 'pool-details',
  templateUrl: './pool-details.component.html',
  styleUrls: [ './pool-details.component.css' ]
})
export class PoolDetailsComponent implements OnInit {

  public poolDetails: any = undefined;
  public poolFields: string[] = [];
  public poolValues: any[] = [];

    constructor(
      private activatedRoute: ActivatedRoute,
      private router: Router,
      private location: Location,
      private web3Service: Web3Service,
      private loading: LoadingService
    ){
    }

    sellingAsset = '';
    buyingAsset = '';

    buyingAssetBalance = '';
    sellingAssetBalance = '';

    async getBalances() {
      const isBuyingA1 = this.buyingAsset === this.poolDetails.asset1Name;
      if (isBuyingA1) {
        this.buyingAssetBalance = 
            await this.web3Service.getBalance(
              this.poolDetails.isAsset1NativeBlockchainCurrency, this.poolDetails.asset1);
        this.sellingAssetBalance = await this.web3Service.getBalance(
              this.poolDetails.isAsset2NativeBlockchainCurrency, this.poolDetails.asset2);
      } else {
        this.buyingAssetBalance = 
            await this.web3Service.getBalance(
              this.poolDetails.isAsset2NativeBlockchainCurrency, this.poolDetails.asset2);
        this.sellingAssetBalance = await this.web3Service.getBalance(
              this.poolDetails.isAsset1NativeBlockchainCurrency, this.poolDetails.asset1);
      }
    }

    async ngOnInit( ) {
      this.activatedRoute.data
      .subscribe(async (data: any) => {
        if (data && data.pool) {
          this.poolDetails = data.pool;
          this.poolFields = [];
          this.poolValues = [];
          for (let field in this.poolDetails) {
            this.poolFields.push(field);
            this.poolValues.push(this.poolDetails[field]);
          }
          this.sellingAsset = this.poolDetails.asset2Name;
          this.buyingAsset = this.poolDetails.asset1Name;

          this.loading.isLoading.next(true);
          this.getBalances();
          this.loading.isLoading.next(false);
        }
      });

      // start loading
      // get balances
      // end loading
    }

    back() {
      this.router.navigate(['pools', CHAIN_HOLDER[0]]);
    }

    sellValue = "";
    buyValue = "";

    sellValueChanged(newSellValue: any) {
      if (this.sellingAsset === this.poolDetails.asset1Name) {
        this.buyValue = ""+ 
        Number.parseFloat(this.sellValue)
        *
        Number.parseFloat(this.poolDetails.currentPriceFor1Asset1InAsset2) ;
      } else {
        this.buyValue = ""+ 
        Number.parseFloat(this.sellValue)
        /
        Number.parseFloat(this.poolDetails.currentPriceFor1Asset1InAsset2);
      }
      // this.buyValue = this.sellValue;
    }

    maxSelling() {
      this.sellValue = this.sellingAssetBalance;
      this.sellValueChanged(this.sellValue);
    }

    async approve() {
      this.loading.isLoading.next(true);
      const isBuyingA1 = this.buyingAsset === this.poolDetails.asset1Name;
      const approved = await this.web3Service.approve(isBuyingA1 
          ? this.poolDetails.asset2
          : this.poolDetails.asset1);
        if (approved) {
          this.isApproveRequired = false;
          this.loading.isLoading.next(false);
        } else {
          this.loading.isLoading.next(false);
        }
    }

    isApproveRequired = false;

    async exchange() {
      this.loading.isLoading.next(true);
      console.log("Selling " + this.sellValue + " " + this.sellingAsset + 
      " for " + this.buyValue + "  " + this.buyingAsset);
      // TODO check by contract, not name
      const isBuyingA1 = this.buyingAsset === this.poolDetails.asset1Name;
      const isSellingNative =
          (isBuyingA1 && this.poolDetails.isAsset2NativeBlockchainCurrency)
          ||
          (!isBuyingA1 && this.poolDetails.isAsset1NativeBlockchainCurrency);
      const tmp = await this.web3Service.exchange(
        this.web3Service.getAddress(),
        this.poolDetails.poolId,
        isSellingNative,
        isBuyingA1,
        this.sellValue,
      );
      if (tmp === 'approveRequired') {
        this.isApproveRequired = true;
      } else if (tmp !== '') {
        console.log('Couldn\'t exchange: ' + tmp);
      }
      this.getBalances()
      this.loading.isLoading.next(false);
      // console.log(tmp);
      // update balances

    }

    swapSellingAsset() {
      let tmp = this.sellingAsset;
      this.sellingAsset = this.buyingAsset;
      this.buyingAsset = tmp;
      this.sellValue = "";
      this.buyValue = "";
      tmp = this.sellingAssetBalance;
      this.sellingAssetBalance = this.buyingAssetBalance;
      this.buyingAssetBalance = tmp;
    }
}

