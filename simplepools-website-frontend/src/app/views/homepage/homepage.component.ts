import { Location } from "@angular/common";
import { HttpClient, HttpHeaders } from "@angular/common/http";
import { Component, OnInit } from "@angular/core";
import { Router } from "@angular/router";
import { LoadingService } from "src/app/services/loading/loading.service";
import { CHAIN_HOLDER } from "src/app/services/web3/web3.service";

@Component({
  selector: 'homepage',
  templateUrl: './homepage.component.html',
  styleUrls: [ './homepage.component.css' ]
})
export class HomepageComponent implements OnInit {

    constructor(
        private router: Router,
        private loading: LoadingService
    ){
    }

    async ngOnInit( ) {
        this.loading.isLoading.next(false);
    }

    showPools() {
        this.router.navigate(['pools', CHAIN_HOLDER[0]]);
    }

    showNftMarketplace() {
        this.router.navigate(['nfts']);
    }
}
