import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { QueryService } from '../services/query.service';
import {
  QueryExecutionRequest,
  QueryExecutionResponse,
  ClusterStatusResponse
} from '../models/query.model';

@Component({
  selector: 'app-query',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './query.component.html',
  styleUrls: ['./query.component.scss']
})
export class QueryComponent implements OnInit {
  // PQDAG Datasets
  pqdagDatasets: string[] = [];
  currentDataset: string = '';
  selectedPqdagDataset: string = '';
  
  // Query files
  queryDatasets: string[] = [];
  selectedQueryDataset: string = '';
  queryFiles: string[] = [];
  selectedQueryFile: string = '';
  queryContent: string = '';
  
  // Cluster status
  clusterStatus: string = 'unknown';
  clusterLoading: boolean = false;
  
  // Query execution
  queryLoading: boolean = false;
  queryResult: QueryExecutionResponse | null = null;
  
  // Advanced options
  showAdvanced: boolean = false;
  masterIp: string = '192.168.165.27';
  planNumber: number = 0;
  
  // Messages
  message: string = '';
  messageType: 'success' | 'error' | 'info' = 'info';

  constructor(private queryService: QueryService) {}

  ngOnInit() {
    this.loadInitialData();
  }

  loadInitialData() {
    this.loadPqdagDatasets();
    this.loadCurrentDataset();
    this.loadQueryDatasets();
  }

  // PQDAG Dataset Management
  loadPqdagDatasets() {
    this.queryService.getPqdagDatasets().subscribe({
      next: (datasets) => {
        // Filter out SSH warnings
        this.pqdagDatasets = datasets.filter(d => !d.includes('Warning') && !d.includes('Permanently'));
        console.log('PQDAG datasets loaded:', this.pqdagDatasets);
      },
      error: (err) => {
        console.error('Error loading PQDAG datasets:', err);
        this.showMessage('Failed to load PQDAG datasets', 'error');
      }
    });
  }

  loadCurrentDataset() {
    this.queryService.getCurrentDataset().subscribe({
      next: (data) => {
        // Clean up SSH warning from output
        this.currentDataset = data.dataset
          .split('\n')
          .filter(line => !line.includes('Warning') && !line.includes('Permanently'))
          .join('')
          .trim();
        this.selectedPqdagDataset = this.currentDataset;
        console.log('Current dataset:', this.currentDataset);
      },
      error: (err) => {
        console.error('Error loading current dataset:', err);
      }
    });
  }

  changeDataset() {
    if (!this.selectedPqdagDataset) {
      this.showMessage('Please select a dataset', 'error');
      return;
    }

    this.clusterLoading = true;
    this.queryService.setDataset(this.selectedPqdagDataset).subscribe({
      next: (response) => {
        this.clusterLoading = false;
        if (response.status === 'success') {
          this.currentDataset = this.selectedPqdagDataset;
          this.showMessage(`Dataset changed to ${this.selectedPqdagDataset}`, 'success');
        } else {
          this.showMessage(response.message, 'error');
        }
      },
      error: (err) => {
        this.clusterLoading = false;
        console.error('Error changing dataset:', err);
        this.showMessage('Failed to change dataset', 'error');
      }
    });
  }

  // Query Dataset Management
  loadQueryDatasets() {
    this.queryService.getQueryDatasets().subscribe({
      next: (datasets) => {
        this.queryDatasets = datasets;
        if (datasets.length > 0) {
          this.selectedQueryDataset = datasets[0];
          this.loadQueryFiles();
        }
      },
      error: (err) => {
        console.error('Error loading query datasets:', err);
        this.showMessage('Failed to load query datasets', 'error');
      }
    });
  }

  loadQueryFiles() {
    if (!this.selectedQueryDataset) return;

    this.queryService.getQueryFiles(this.selectedQueryDataset).subscribe({
      next: (files) => {
        this.queryFiles = files;
        if (files.length > 0) {
          this.selectedQueryFile = files[0];
          this.loadQueryContent();
        }
      },
      error: (err) => {
        console.error('Error loading query files:', err);
        this.showMessage('Failed to load query files', 'error');
      }
    });
  }

  onQueryDatasetChange() {
    this.loadQueryFiles();
  }

  onQueryFileChange() {
    this.loadQueryContent();
  }

  loadQueryContent() {
    if (!this.selectedQueryDataset || !this.selectedQueryFile) return;

    this.queryService.getQueryContent(this.selectedQueryDataset, this.selectedQueryFile).subscribe({
      next: (data) => {
        this.queryContent = data.content;
      },
      error: (err) => {
        console.error('Error loading query content:', err);
        this.queryContent = 'Error loading query content';
      }
    });
  }

  // Cluster Management
  startCluster() {
    this.clusterLoading = true;
    this.clusterStatus = 'starting';
    this.queryService.startCluster().subscribe({
      next: (response) => {
        this.clusterLoading = false;
        if (response.status === 'success') {
          this.clusterStatus = 'running';
          this.showMessage('Cluster started successfully', 'success');
        } else {
          this.clusterStatus = 'error';
          this.showMessage(response.message, 'error');
        }
      },
      error: (err) => {
        this.clusterLoading = false;
        this.clusterStatus = 'error';
        console.error('Error starting cluster:', err);
        this.showMessage('Failed to start cluster', 'error');
      }
    });
  }

  stopCluster() {
    this.clusterLoading = true;
    this.clusterStatus = 'stopping';
    this.queryService.stopCluster().subscribe({
      next: (response) => {
        this.clusterLoading = false;
        if (response.status === 'success') {
          this.clusterStatus = 'stopped';
          this.showMessage('Cluster stopped successfully', 'success');
        } else {
          this.clusterStatus = 'error';
          this.showMessage(response.message, 'error');
        }
      },
      error: (err) => {
        this.clusterLoading = false;
        this.clusterStatus = 'error';
        console.error('Error stopping cluster:', err);
        this.showMessage('Failed to stop cluster', 'error');
      }
    });
  }

  restartCluster() {
    this.clusterLoading = true;
    this.clusterStatus = 'restarting';
    this.queryService.restartCluster().subscribe({
      next: (response) => {
        this.clusterLoading = false;
        if (response.status === 'success') {
          this.clusterStatus = 'running';
          this.showMessage('Cluster restarted successfully', 'success');
        } else {
          this.clusterStatus = 'error';
          this.showMessage(response.message, 'error');
        }
      },
      error: (err) => {
        this.clusterLoading = false;
        this.clusterStatus = 'error';
        console.error('Error restarting cluster:', err);
        this.showMessage('Failed to restart cluster', 'error');
      }
    });
  }

  clearJavaProcesses() {
    this.clusterLoading = true;
    this.queryService.clearJavaProcesses().subscribe({
      next: (response) => {
        this.clusterLoading = false;
        if (response.status === 'success') {
          this.clusterStatus = 'stopped';
          this.showMessage(response.message, 'success');
        } else {
          this.showMessage(response.message, 'error');
        }
      },
      error: (err) => {
        this.clusterLoading = false;
        console.error('Error clearing Java processes:', err);
        this.showMessage('Failed to clear Java processes', 'error');
      }
    });
  }

  // Query Execution
  executeQuery() {
    if (!this.selectedQueryFile) {
      this.showMessage('Please select a query file', 'error');
      return;
    }

    const request: QueryExecutionRequest = {
      dataset: this.selectedQueryDataset,
      queryFile: this.selectedQueryFile,
      masterIp: this.masterIp,
      planNumber: this.planNumber
    };

    this.queryLoading = true;
    this.queryResult = null;
    
    this.queryService.executeQuery(request).subscribe({
      next: (response) => {
        this.queryLoading = false;
        this.queryResult = response;
        if (response.status === 'success') {
          this.showMessage(`Query executed in ${response.executionTimeMs}ms`, 'success');
        } else {
          this.showMessage(response.message, 'error');
        }
      },
      error: (err) => {
        this.queryLoading = false;
        console.error('Error executing query:', err);
        this.showMessage('Failed to execute query', 'error');
      }
    });
  }

  // Utility
  showMessage(msg: string, type: 'success' | 'error' | 'info') {
    this.message = msg;
    this.messageType = type;
    setTimeout(() => {
      this.message = '';
    }, 5000);
  }

  toggleAdvanced() {
    this.showAdvanced = !this.showAdvanced;
  }
}
