import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterOutlet } from '@angular/router';
import { FileUploadComponent } from './components/file-upload/file-upload.component';
import { FragmentationResultsComponent } from './components/fragmentation-results/fragmentation-results.component';
import { AllocationComponent } from './allocation/allocation.component';
import { FragmentationService } from './services/fragmentation.service';
import { FragmentationResult } from './models/fragmentation.model';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [
    CommonModule,
    RouterOutlet,
    FileUploadComponent,
    FragmentationResultsComponent,
    AllocationComponent
  ],
  templateUrl: './app.component.html',
  styleUrl: './app.component.scss'
})
export class AppComponent {
  title = 'PQDAG - Fragmentation GUI';
  currentView: 'fragmentation' | 'allocation' = 'fragmentation';
  fragmentationResult: FragmentationResult | null = null;
  isProcessing = false;
  errorMessage = '';

  constructor(private fragmentationService: FragmentationService) {}

  startFragmentation(cleanAfter: boolean = false) {
    this.isProcessing = true;
    this.errorMessage = '';
    this.fragmentationResult = null;

    this.fragmentationService.startFragmentation({ cleanAfter }).subscribe({
      next: (result) => {
        this.isProcessing = false;
        this.fragmentationResult = result;
      },
      error: (error) => {
        this.isProcessing = false;
        this.errorMessage = error.error?.message || 'Fragmentation failed. Please try again.';
      }
    });
  }
}
