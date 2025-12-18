export interface QueryExecutionRequest {
  dataset: string;
  queryFile: string;
  masterIp?: string;
  planNumber?: number;
}

export interface QueryExecutionResponse {
  status: string;
  message: string;
  queryFile?: string;
  executionTimeMs?: number;
  resultCount?: number;
  output?: string;
  results?: string[];
}

export interface ClusterStatusResponse {
  status: string;
  message: string;
  output?: string;
}

export interface DatasetInfo {
  dataset: string;
}
