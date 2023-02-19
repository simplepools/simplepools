import { Location } from "@angular/common";
import { HttpClient, HttpHeaders } from "@angular/common/http";
import { Component, OnInit, ViewEncapsulation } from "@angular/core";
import { __core_private_testing_placeholder__ } from "@angular/core/testing";
import { ActivatedRoute, Route, Router } from "@angular/router";
import { ErrorService } from "src/app/services/error/error.service";
import { environment } from "src/environments/environment";
import Web3 from "web3";
import { LoadingService } from "../../../services/loading/loading.service";
import * as ethers from "ethers"
import { blockchain } from "../pools-routing.module";
import { contractTax, Web3Service } from "src/app/services/web3/web3.service";
import importedAssetCode from  "./asset_code.json";
import { Subject } from 'rxjs';



@Component({
  selector: 'create-asset',
  templateUrl: './create-asset.component.html',
  styleUrls: [ './create-asset.component.scss' ],
  encapsulation: ViewEncapsulation.None
})
export class CreateAssetComponent implements OnInit {

  assetName = '';
  assetSymbol = '';
  assetTotalSupply = '';

  constructor(
      private activatedRoute: ActivatedRoute,
      private router: Router,
      private location: Location,
      private web3Service: Web3Service,
      private loading: LoadingService
    ){
    }


    async ngOnInit( ) {
    }

    back() {
      this.router.navigate(['pools', blockchain]);
    }

    reviewActive = false;
    assetCode = '';

    async review() {
      this.reviewActive = true;
      this.assetCode = importedAssetCode.replace(/###ASSET_NAME###/g, this.assetName);
      this.assetCode = this.assetCode.replace(/###ASSET_SYMBOL###/g, this.assetSymbol);
      this.assetCode = this.assetCode.replace(/###TOTAL_SUPPLY###/g, this.assetTotalSupply + '_000000000000000000');
      console.log(this.assetCode);
      // this.loading.isLoading.next(true);
      // console.log(this);
      // const res = await this.web3Service.createPool(
      //   this.asset1,
      //   this.isAsset1Native,
      //   this.asset2,
      //   this.isAsset2Native,
      //   this.asset1Amount,
      //   this.asset2InitiallyAskedAmount,
      //   this.maxBuyAsset1PercentPerTransaction,
      //   this.isConstantPrice
      // );
      // console.log(res);
      // this.loading.isLoading.next(false);
      // if (res == 'approveRequired') {
      //   this.isApproveRequired = true;
      // }
    }

    contractAddress: any;

    async deploy() {
      this.loading.isLoading.next(true);
      console.log("DEPLOY");
      let contractAddressSubject = new Subject<string>();
      this.web3Service.deploy({
        assetCode: this.assetCode,
        contractName: this.assetSymbol,
        contractAddressSubject,
      });

      contractAddressSubject.subscribe((address: any) => {
        this.contractAddress = `https://sepolia.etherscan.io/verifyContract-solc?a=${address}&c=v0.8.17%2bcommit.8df45f5f&lictype=5`;
      });
    }

}

