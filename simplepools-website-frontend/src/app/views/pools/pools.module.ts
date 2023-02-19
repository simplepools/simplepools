import { CommonModule } from "@angular/common";
import { CUSTOM_ELEMENTS_SCHEMA, NgModule } from "@angular/core";
import { FormsModule } from "@angular/forms";
import { MatButtonModule } from "@angular/material/button";
import { MatRippleModule } from "@angular/material/core";
import { MatDialogModule } from "@angular/material/dialog";
import { MatInputModule } from "@angular/material/input";
import { MatProgressSpinnerModule } from "@angular/material/progress-spinner";
import { MatTableModule } from "@angular/material/table";
import {MatCardModule} from '@angular/material/card';
import { MatTabsModule } from "@angular/material/tabs";
import { BrowserModule } from "@angular/platform-browser";
import { BrowserAnimationsModule } from "@angular/platform-browser/animations";
import { PoolDetailsResolverService } from "./pool-details-resolver.service";
import { PoolDetailsComponent } from "./pool-details/pool-details.component";
import { PoolsListComponent } from "./pools-list/pools-list.component";
import { PoolsRoutingModule } from "./pools-routing.module";
import { PoolsComponent } from "./pools.component";
import { PoolsService } from "./pools.service";
import {MatFormFieldModule} from '@angular/material/form-field';
import {MatSelectModule} from '@angular/material/select';
import { HttpClientModule } from '@angular/common/http';
import {MatPaginatorModule} from '@angular/material/paginator';
import { MatIconModule } from "@angular/material/icon";
import {MatCheckboxModule} from '@angular/material/checkbox';

import { CreatePoolComponent } from "./create-pool/create-pool.component";
import { CreateAssetComponent } from "./create-asset/create-asset.component";


@NgModule({
    imports: [
      CommonModule,
      BrowserAnimationsModule,
      BrowserModule,
      FormsModule,
      PoolsRoutingModule,
      MatProgressSpinnerModule,
      MatButtonModule,
      MatCheckboxModule,
      MatInputModule,
      MatTableModule,
      MatTabsModule,
      MatCardModule,
      MatDialogModule,
      MatRippleModule,
      MatPaginatorModule,
      HttpClientModule,
      MatFormFieldModule,
      MatIconModule,
      MatSelectModule,
    ],
    declarations: [
      PoolsListComponent,
      PoolsComponent,
      CreatePoolComponent,
      CreateAssetComponent,
      PoolDetailsComponent,
    ],
    schemas: [
      CUSTOM_ELEMENTS_SCHEMA,
    ]
  })
  export class PoolsModule {}