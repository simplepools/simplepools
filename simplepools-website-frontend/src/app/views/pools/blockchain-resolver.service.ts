
import { Injectable }             from '@angular/core';
import {
  Router, Resolve,
  RouterStateSnapshot,
  ActivatedRouteSnapshot
}                                 from '@angular/router';
import { Observable, of, EMPTY }  from 'rxjs';
import { mergeMap, take, map }         from 'rxjs/operators';
import { BLOCKCHAIN_PARAM_NAME, CHAINS_METADATA } from 'src/app/services/web3/web3.service';
import { PoolsResponse, PoolsService } from './pools.service';


@Injectable({
  providedIn: 'root',
})
export class BlockchainResolverService implements Resolve<any> {
  constructor(private poolsService: PoolsService, private router: Router) {}

  resolve(route: ActivatedRouteSnapshot, state: RouterStateSnapshot): Observable<any> {
    let blockchain = route.paramMap.get(BLOCKCHAIN_PARAM_NAME)?.trim();
    for (let i = 0; i < CHAINS_METADATA.length; ++i) {
      if (blockchain === CHAINS_METADATA[i].paramName) {
        return of(true);
      }
    }
    return EMPTY;
  
  }
}

