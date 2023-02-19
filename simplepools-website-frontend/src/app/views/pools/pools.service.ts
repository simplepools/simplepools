
import { HttpClient } from '@angular/common/http';
import { Injectable }             from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { of } from "rxjs";

import { map } from 'rxjs/operators';
import { delay } from "rxjs/operators";


export interface PoolsResponse {
  poolsOnPage: any[];
  poolsMedatada: any[];
  totalNumberOfPools: number;
}
  

@Injectable({
    providedIn: 'root',
  })
export class PoolsService {

  constructor(private http: HttpClient) {

  }

    getPools(from: number,
             to: number, 
             blockchain: string,
    ): Observable<any> {
      return this.http.get<PoolsResponse>('services/pools',
        {
          params: {
            from: from,
            to: to,
            blockchain: blockchain,
          }
        }).pipe(map((pools: PoolsResponse) => {
          for (let i = 0; i < pools.poolsOnPage.length; ++i) {
            let poolM = pools.poolsMedatada[i];
            for (let field in poolM) {
              pools.poolsOnPage[i][field] = poolM[field];
            }
          }
          return pools;
        }));
     }

    getPool(poolId: number, blockchain: string): Observable<PoolsResponse> {
      return this.getPools(poolId, poolId + 1, blockchain);
    }

    // public getPools(): PoolDetails[] {
    //     return ELEMENT_DATA;
    // }

    // public getPool(poolId: number): PoolDetails | undefined {
    //     if (poolId >= 0 && ELEMENT_DATA.length > poolId) {
    //         return ELEMENT_DATA[poolId];
    //     }
    //     return undefined;
    // }

}