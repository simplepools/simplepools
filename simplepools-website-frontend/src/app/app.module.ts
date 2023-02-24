import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { FormsModule } from '@angular/forms';
import { HttpClientModule, HTTP_INTERCEPTORS } from '@angular/common/http';
import { AppComponent } from './app.component';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatButtonModule } from '@angular/material/button';
import { MatInputModule } from '@angular/material/input';
import { MatTableModule } from '@angular/material/table';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { LoadingComponent } from './components/loading/loading.component';
import { LoadingService } from './services/loading/loading.service';
import { LoadingInterceptor } from './interceptors/loading-interceptor';
import { MatTabsModule } from '@angular/material/tabs';
import { MatDialogModule } from '@angular/material/dialog';
import { PoolsComponent } from './views/pools/pools.component';
import { HomepageComponent } from './views/homepage/homepage.component';
import { PreloadAllModules, RouterModule, Routes } from '@angular/router';
import { MatRippleModule } from '@angular/material/core';
import { PoolsListComponent } from './views/pools/pools-list/pools-list.component';
import { PoolsModule } from './views/pools/pools.module';
import {MatIconModule} from '@angular/material/icon'


import { Web3Service } from './services/web3/web3.service';
import { UnderDevelopmentComponent } from './views/under-development/under-development.component';

export const routes: Routes = [
  { 
    path: 'homepage', 
    component: HomepageComponent,
    data: {
      animation: 'homepage',
    }
  },
  {
    path: 'nfts',
    component: UnderDevelopmentComponent,
    data: { animation: 'pools' },
  },
  {
    path: 'pools/:blockchain',
    loadChildren: () => import("./views/pools/pools.module").then(m => m.PoolsModule),
    data: { preload: true }
  },
  { path: '',   redirectTo: '/homepage', pathMatch: 'full' },
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
    BrowserModule,
    FormsModule,
    BrowserAnimationsModule,
    HttpClientModule,
    MatProgressSpinnerModule,
    MatButtonModule,
    MatInputModule,
    MatTableModule,
    MatTabsModule,
    MatDialogModule,
    RouterModule,
    MatIconModule,
    MatRippleModule,
    PoolsModule,
    RouterModule.forRoot(routes, { useHash: true }),
    // The HttpClientInMemoryWebApiModule module intercepts HTTP requests
    // and returns simulated server responses.
    // Remove it when a real server is ready to receive requests.
    // HttpClientInMemoryWebApiModule.forRoot(
    //   InMemoryDataService, { dataEncapsulation: false }
    // )
  ],
  declarations: [
    AppComponent,
    LoadingComponent,
    HomepageComponent,
    UnderDevelopmentComponent,
  ],
  bootstrap: [ AppComponent ],
  providers: [
    Web3Service,
    LoadingService,
    { provide: HTTP_INTERCEPTORS, useClass: LoadingInterceptor, multi: true }
  ]
})
export class AppModule { }
