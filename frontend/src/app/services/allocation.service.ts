import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

export interface AllocationRequest {
  datasetName: string;
  numMachines: number;
  cleanAfter?: boolean;
}

export interface AllocationStatistics {
  totalFragments: number;
  totalEdges: number;
  executionTime: number;
  dbStatFile: string;
  graphFile: string;
}

export interface MachineAllocation {
  machineId: number;
  fragmentCount: number;
  workerIp: string;
}

export interface AllocationResponse {
  status: string;
  message: string;
  statistics: AllocationStatistics;
  distribution: MachineAllocation[];
  affectationFile: string;
}

export interface DistributionRequest {
  datasetName: string;
  cleanAfter?: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class AllocationService {
  private apiUrl = `${environment.apiUrl}/allocation`;

  constructor(private http: HttpClient) { }

  /**
   * Start allocation process (stats + graph + METIS)
   */
  startAllocation(request: AllocationRequest): Observable<AllocationResponse> {
    return this.http.post<AllocationResponse>(`${this.apiUrl}/start`, request);
  }

  /**
   * Distribute fragments to cluster
   */
  distributeFragments(request: DistributionRequest): Observable<AllocationResponse> {
    return this.http.post<AllocationResponse>(`${this.apiUrl}/distribute`, request);
  }

  /**
   * Get allocation results for a dataset
   */
  getResults(datasetName: string): Observable<AllocationResponse> {
    return this.http.get<AllocationResponse>(`${this.apiUrl}/results/${datasetName}`);
  }
}
