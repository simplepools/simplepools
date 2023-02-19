
import { Injectable }             from '@angular/core';
import {
  Router, Resolve,
  RouterStateSnapshot,
  ActivatedRouteSnapshot
}                                 from '@angular/router';
import { Observable, of, EMPTY }  from 'rxjs';
import { mergeMap, take, map }         from 'rxjs/operators';
import { PoolsResponse, PoolsService } from './pools.service';


@Injectable({
  providedIn: 'root',
})
export class PoolDetailsResolverService implements Resolve<any> {
  constructor(private poolsService: PoolsService, private router: Router) {}

  resolve(route: ActivatedRouteSnapshot, state: RouterStateSnapshot): Observable<any> {
    let poolId = route.paramMap.get('poolId')?.trim();
    const blockchainParamName = 'blockchain';
    let blockchain = route.parent?.paramMap.get(blockchainParamName)?.trim() ||
         route.paramMap.get(blockchainParamName)?.trim();
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

