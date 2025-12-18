import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import {
  QueryExecutionRequest,
  QueryExecutionResponse,
  ClusterStatusResponse,
  DatasetInfo
} from '../models/query.model';

@Injectable({
  providedIn: 'root'
})
export class QueryService {
  private apiUrl = `${environment.apiUrl}/query`;

  constructor(private http: HttpClient) {}

  // Query datasets (watdiv queries)
  getQueryDatasets(): Observable<string[]> {
    return this.http.get<string[]>(`${this.apiUrl}/datasets`);
  }

  getQueryFiles(dataset: string): Observable<string[]> {
    return this.http.get<string[]>(`${this.apiUrl}/files/${dataset}`);
  }

  getQueryContent(dataset: string, queryFile: string): Observable<{content: string}> {
    return this.http.get<{content: string}>(`${this.apiUrl}/content/${dataset}/${queryFile}`);
  }

  // PQDAG datasets (from pqdag_data)
  getPqdagDatasets(): Observable<string[]> {
    return this.http.get<string[]>(`${this.apiUrl}/pqdag-datasets`);
  }

  getCurrentDataset(): Observable<DatasetInfo> {
    return this.http.get<DatasetInfo>(`${this.apiUrl}/current-dataset`);
  }

  setDataset(dataset: string): Observable<ClusterStatusResponse> {
    return this.http.post<ClusterStatusResponse>(`${this.apiUrl}/set-dataset/${dataset}`, {});
  }

  // Cluster management
  startCluster(): Observable<ClusterStatusResponse> {
    return this.http.post<ClusterStatusResponse>(`${this.apiUrl}/start-cluster`, {});
  }

  stopCluster(): Observable<ClusterStatusResponse> {
    return this.http.post<ClusterStatusResponse>(`${this.apiUrl}/stop-cluster`, {});
  }

  restartCluster(): Observable<ClusterStatusResponse> {
    return this.http.post<ClusterStatusResponse>(`${this.apiUrl}/restart-cluster`, {});
  }

  clearJavaProcesses(): Observable<ClusterStatusResponse> {
    return this.http.post<ClusterStatusResponse>(`${this.apiUrl}/clear-java-processes`, {});
  }

  // Query execution
  executeQuery(request: QueryExecutionRequest): Observable<QueryExecutionResponse> {
    return this.http.post<QueryExecutionResponse>(`${this.apiUrl}/execute`, request);
  }
}
