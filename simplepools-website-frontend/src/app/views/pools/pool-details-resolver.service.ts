
import { Injectable }             from '@angular/core';
import {
  Router, Resolve,
  RouterStateSnapshot,
  ActivatedRouteSnapshot
}                                 from '@angular/router';
import { Observable, of, EMPTY }  from 'rxjs';
import { mergeMap, take, map }         from 'rxjs/operators';
import { BLOCKCHAIN_PARAM_NAME } from 'src/app/services/web3/web3.service';
import { PoolsResponse, PoolsService } from './pools.service';


@Injectable({
  providedIn: 'root',
})
export class PoolDetailsResolverService implements Resolve<any> {
  constructor(private poolsService: PoolsService, private router: Router) {}

  resolve(route: ActivatedRouteSnapshot, state: RouterStateSnapshot): Observable<any> {
    let poolId = route.paramMap.get('poolId')?.trim();
    let blockchain = route.parent?.paramMap.get(BLOCKCHAIN_PARAM_NAME)?.trim() ||
         route.paramMap.get(BLOCKCHAIN_PARAM_NAME)?.trim();
    if (!blockchain) {
      return EMPTY;
    }

    return this.poolsService.getPool(Number.parseInt(poolId || '0'), blockchain)
        .pipe(map((pools: PoolsResponse) => {
          if (pools && pools.poolsOnPage && pools.poolsOnPage.length > 0) {
            return pools.poolsOnPage[0];
          } else {
            this.router.navigate(['/pools']);
            return EMPTY;
          }
        }));
  
  }
}

