import { Location } from "@angular/common";
import { HttpClient, HttpHeaders } from "@angular/common/http";
import { Component, OnInit } from "@angular/core";
import { Router } from "@angular/router";
import { LoadingService } from "src/app/services/loading/loading.service";
import { defaultBlockchain } from "../pools/pools-routing.module";

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
        this.router.navigate(['pools', defaultBlockchain]);
    }

    showNftMarketplace() {
        console.log("in development....");
    }
}
