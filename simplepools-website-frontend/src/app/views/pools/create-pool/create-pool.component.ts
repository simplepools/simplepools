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


@Component({
  selector: 'create-pool',
  templateUrl: './create-pool.component.html',
  styleUrls: [ './create-pool.component.scss' ],
  encapsulation: ViewEncapsulation.None
})
export class CreatePoolComponent implements OnInit {

  asset1: any;
  asset1Amount: any;
  isAsset1Native = false;
  asset2: any;
  isAsset2Native = false;
  asset2InitiallyAskedAmount: any;
  maxBuyAsset1PercentPerTransaction: any;
  isConstantPrice = false;
  
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

    isApproveRequired = false;

    async create() {
      this.loading.isLoading.next(true);
      console.log(this);
      const res = await this.web3Service.createPool(
        this.asset1,
        this.isAsset1Native,
        this.asset2,
        this.isAsset2Native,
        this.asset1Amount,
        this.asset2InitiallyAskedAmount,
        this.maxBuyAsset1PercentPerTransaction,
        this.isConstantPrice
      );
      console.log(res);
      this.loading.isLoading.next(false);
      if (res == 'approveRequired') {
        this.isApproveRequired = true;
      }
    }

    async approve() {
      this.loading.isLoading.next(true);
      const approved = await this.web3Service.approve(this.asset1);
        if (approved) {
          this.isApproveRequired = false;
          this.loading.isLoading.next(false);
        } else {
          this.loading.isLoading.next(false);
        }
    }

}

