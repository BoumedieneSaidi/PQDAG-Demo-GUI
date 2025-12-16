import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { AllocationService, AllocationRequest, AllocationResponse, MachineAllocation } from '../services/allocation.service';

@Component({
  selector: 'app-allocation',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './allocation.component.html',
  styleUrl: './allocation.component.scss'
})
export class AllocationComponent implements OnInit {
  // Form data
  datasetName: string = 'watdiv100k';
  numMachines: number = 10;
  cleanAfter: boolean = true;
  
  // State
  isAllocating: boolean = false;
  isDistributing: boolean = false;
  allocationCompleted: boolean = false;
  distributionCompleted: boolean = false;
  
  // Results
  allocationResponse: AllocationResponse | null = null;
  errorMessage: string = '';
  
  // Progress steps
  currentStep: number = 0;
  steps = [
    { name: 'Statistics Generation', description: 'Running stat_MPI.py with MPI', completed: false },
    { name: 'Graph Generation', description: 'Creating dependency graph', completed: false },
    { name: 'METIS Partitioning', description: 'Optimal allocation with METIS', completed: false },
    { name: 'Distribution', description: 'Deploying to cluster', completed: false }
  ];

  constructor(private allocationService: AllocationService) {}

  ngOnInit(): void {
    // Initialize with clean state
    this.resetProgress();
  }

  /**
   * Reset progress state
   */
  resetProgress(): void {
    this.currentStep = 0;
    this.steps.forEach(step => step.completed = false);
    this.allocationCompleted = false;
    this.distributionCompleted = false;
  }

  /**
   * Load existing allocation results if available
   */
  loadExistingResults(): void {
    this.allocationService.getResults(this.datasetName).subscribe({
      next: (response) => {
        if (response.status === 'success' && response.statistics) {
          this.allocationResponse = response;
          this.allocationCompleted = true;
          this.steps[0].completed = true;
          this.steps[1].completed = true;
          this.steps[2].completed = true;
          this.currentStep = 3;
        }
      },
      error: () => {
        // No existing results, that's fine
        this.resetProgress();
      }
    });
  }

  /**
   * Start allocation process
   */
  startAllocation(): void {
    this.isAllocating = true;
    this.errorMessage = '';
    this.currentStep = 0;
    this.resetSteps();
    
    const request: AllocationRequest = {
      datasetName: this.datasetName,
      numMachines: this.numMachines,
      cleanAfter: true
    };

    // Simulate progress (since we can't track real progress without WebSocket)
    this.simulateProgress();

    this.allocationService.startAllocation(request).subscribe({
      next: (response) => {
        this.isAllocating = false;
        this.allocationResponse = response;
        this.allocationCompleted = true;
        this.steps[0].completed = true;
        this.steps[1].completed = true;
        this.steps[2].completed = true;
        // Don't set currentStep to 3, leave it at completed state
      },
      error: (error) => {
        this.isAllocating = false;
        this.errorMessage = error.error?.message || 'Allocation failed. Please check the logs.';
        console.error('Allocation error:', error);
      }
    });
  }

  /**
   * Simulate progress for UX (will be replaced with WebSocket in future)
   */
  simulateProgress(): void {
    const intervals = [3000, 5000, 8000]; // Simulated delays for each step
    
    intervals.forEach((delay, index) => {
      setTimeout(() => {
        if (this.isAllocating && index < this.steps.length - 1) {
          this.steps[index].completed = true;
          this.currentStep = index + 1;
        }
      }, delay);
    });
  }

  /**
   * Distribute fragments to cluster
   */
  distributeToCluster(): void {
    this.isDistributing = true;
    this.errorMessage = '';

    this.allocationService.distributeFragments({ 
      datasetName: this.datasetName,
      cleanAfter: this.cleanAfter
    }).subscribe({
      next: (response) => {
        this.isDistributing = false;
        this.distributionCompleted = true;
        this.steps[3].completed = true;
      },
      error: (error) => {
        this.isDistributing = false;
        this.errorMessage = error.error?.message || 'Distribution failed. Please check SSH connectivity.';
        console.error('Distribution error:', error);
      }
    });
  }

  /**
   * Reset progress steps
   */
  resetSteps(): void {
    this.steps.forEach(step => step.completed = false);
    this.allocationCompleted = false;
    this.distributionCompleted = false;
  }

  /**
   * Get distribution chart data
   */
  getChartData(): { label: string, value: number, color: string }[] {
    if (!this.allocationResponse?.distribution) {
      return [];
    }

    return this.allocationResponse.distribution.map((machine, index) => ({
      label: `Worker ${machine.machineId}`,
      value: machine.fragmentCount,
      color: this.getBarColor(index)
    }));
  }

  /**
   * Get color for bar chart
   */
  getBarColor(index: number): string {
    const colors = [
      '#3b82f6', '#8b5cf6', '#ec4899', '#f59e0b', 
      '#10b981', '#06b6d4', '#6366f1', '#f97316',
      '#14b8a6', '#a855f7'
    ];
    return colors[index % colors.length];
  }

  /**
   * Format number with separators
   */
  formatNumber(num: number): string {
    return num?.toLocaleString() || '0';
  }

  /**
   * Get max fragment count for chart scaling
   */
  getMaxFragmentCount(): number {
    if (!this.allocationResponse?.distribution) {
      return 100;
    }
    return Math.max(...this.allocationResponse.distribution.map(m => m.fragmentCount));
  }
}
