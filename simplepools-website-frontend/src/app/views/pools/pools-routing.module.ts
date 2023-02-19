import { NgModule }             from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { CreateAssetComponent } from './create-asset/create-asset.component';
import { CreatePoolComponent } from './create-pool/create-pool.component';
import { PoolDetailsResolverService } from './pool-details-resolver.service';
import { PoolDetailsComponent } from './pool-details/pool-details.component';
import { PoolsListComponent } from './pools-list/pools-list.component';

import { PoolsComponent } from './pools.component';

export const defaultBlockchain = 'sepolia';
export let blockchain = defaultBlockchain;

const poolRoutes: Routes = [
    {
        path: 'pools/:blockchain',
        component: PoolsComponent,
        data: { animation: 'pools' },
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
      redirectTo: 'pools/' + defaultBlockchain,
      pathMatch: 'full',
    },
    { 
        path: '**', 
        redirectTo: '/homepage',
        pathMatch: 'full',
        data: {
            animation: 'homepage',
        }
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

