import { NgModule }             from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { CHAIN_HOLDER } from 'src/app/services/web3/web3.service';
import { BlockchainResolverService } from './blockchain-resolver.service';
import { CreateAssetComponent } from './create-asset/create-asset.component';
import { CreatePoolComponent } from './create-pool/create-pool.component';
import { PoolDetailsResolverService } from './pool-details-resolver.service';
import { PoolDetailsComponent } from './pool-details/pool-details.component';
import { PoolsListComponent } from './pools-list/pools-list.component';

import { PoolsComponent } from './pools.component';

const poolRoutes: Routes = [
    {
        path: 'pools/:blockchain',
        component: PoolsComponent,
        data: { animation: 'pools' },
        resolve: {
          blockchain: BlockchainResolverService,
        },
        children: [
          {
            path: '',
            component: PoolsListComponent,
            data: { animation: 'pools' },
          },
          {
            path: 'pool-details/:poolId',
            component: PoolDetailsComponent,
            data: { animation: 'pool-details' },
            resolve: {
                pool: PoolDetailsResolverService
            }
          },
          {
            path: 'create-pool',
            component: CreatePoolComponent,
          },
          {
            path: 'create-asset',
            component: CreateAssetComponent,
          },
        ]
    },
    {
      path: 'pools',
      redirectTo: 'pools/' + CHAIN_HOLDER[0],
      pathMatch: 'full',
    },
];

@NgModule({
  imports: [
    RouterModule.forChild(poolRoutes)
  ],
  exports: [
    RouterModule
  ]
})
export class PoolsRoutingModule { }

