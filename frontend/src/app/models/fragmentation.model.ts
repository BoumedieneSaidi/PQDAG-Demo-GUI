export interface FragmentationRequest {
  cleanAfter?: boolean;
}

export interface FragmentationResult {
  success: boolean;
  message: string;
  fragmentCount: number;
  totalTriples: number;
  executionTimeSeconds: number;
  throughput: number;
  dockerOutput: string;
  encodingTime: number | null;
  dictionariesTime: number | null;
  sortingTime: number | null;
  fragmentationTime: number | null;
  reencodingTime: number | null;
}

export interface UploadResponse {
  success: boolean;
  message: string;
  fileNames: string[];
  totalSize: number;
  fileCount: number;
}
