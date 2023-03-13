import { Location } from "@angular/common";
import { HttpClient, HttpHeaders } from "@angular/common/http";
import { Component, OnInit, ViewChild, AfterViewInit, OnChanges, SimpleChanges, NgZone } from "@angular/core";
import { __core_private_testing_placeholder__ } from "@angular/core/testing";
import { ActivatedRoute, ChildrenOutletContexts, Route, Router, RouterOutlet } from "@angular/router";
import { ErrorService } from "src/app/services/error/error.service";
import { environment } from "src/environments/environment";
import Web3 from "web3";
import { LoadingService } from "../../services/loading/loading.service";
import { slideInAnimation } from "src/app/animations";

import { configureChains, createClient } from '@wagmi/core'
import { mainnet, bsc, polygon, avalanche, fantom, optimism, gnosis, sepolia } from '@wagmi/core/chains'
import { EthereumClient, modalConnectors, walletConnectProvider } from '@web3modal/ethereum'
import { Web3Modal } from '@web3modal/html'
import { ViewEncapsulation } from "@angular/core";
import { CHAINS_METADATA, CHAIN_CHANGED_SUBJECT, CHAIN_HOLDER, ETHEREUM_CLIENT, WEB3_MODAL, Web3Service, WEB3_MODAL_STATE_SUBJECT } from "src/app/services/web3/web3.service";

@Component({
  selector: 'pools',
  templateUrl: './pools.component.html',
  styleUrls: [ './pools.component.scss' ],
  animations: [ slideInAnimation ],
  encapsulation: ViewEncapsulation.None
})
export class PoolsComponent implements OnInit, AfterViewInit {

// TODO When row is clicked navigate to the subpage with animation to row details component
// animation enlarge from list row
// animation on close make smaller
    constructor(
      public router: Router,
      public activatedRoute: ActivatedRoute,
      private contexts: ChildrenOutletContexts,
      private web3Service: Web3Service,
      private ngZone: NgZone
    ){
    }
    

    ngOnInit( ) {
      WEB3_MODAL_STATE_SUBJECT.subscribe((x: any) => {
        if (!x.open) {
          for (let i = 0; i < CHAINS_METADATA.length; ++i) {
            if (CHAINS_METADATA[i].name === this.networkSwitch.nativeElement.label) {
              const chainParam = CHAINS_METADATA[i].paramName;
              if (chainParam !== CHAIN_HOLDER[0]) {
                CHAIN_CHANGED_SUBJECT.next(chainParam);
                this.ngZone.run(() => {
                  this.router.navigate(['pools', chainParam]);
                });
              }
              break;
            }
          }
        }
      });
    }

    ngAfterViewInit(): void {
    }

    @ViewChild('networkSwitch') networkSwitch: any;

    getPoolAnimationData() {
      const animation = this.contexts.getContext('primary')?.route?.snapshot?.data?.['animation'];
      return animation;
    }

}

