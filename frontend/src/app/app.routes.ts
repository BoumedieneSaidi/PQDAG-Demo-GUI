import { Routes } from '@angular/router';
import { AllocationComponent } from './allocation/allocation.component';
import { QueryComponent } from './query/query.component';

export const routes: Routes = [
  { path: '', redirectTo: '/allocation', pathMatch: 'full' },
  { path: 'allocation', component: AllocationComponent },
  { path: 'query', component: QueryComponent }
];
