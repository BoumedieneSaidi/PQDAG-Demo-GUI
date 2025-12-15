import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { UploadResponse } from '../models/fragmentation.model';
import { API_CONFIG } from '../config/api.config';

@Injectable({
  providedIn: 'root'
})
export class FileService {
  private apiUrl = API_CONFIG.apiUrl;

  constructor(private http: HttpClient) { }

  /**
   * Upload RDF files to the server
   */
  uploadFiles(files: FileList): Observable<UploadResponse> {
    const formData = new FormData();
    for (let i = 0; i < files.length; i++) {
      formData.append('files', files[i], files[i].name);
    }
    return this.http.post<UploadResponse>(`${this.apiUrl}/files/upload`, formData);
  }

  /**
   * List uploaded files
   */
  listFiles(): Observable<UploadResponse> {
    return this.http.get<UploadResponse>(`${this.apiUrl}/files/list`);
  }

  /**
   * Clear all uploaded files
   */
  clearFiles(): Observable<{ success: boolean; message: string }> {
    return this.http.delete<{ success: boolean; message: string }>(`${this.apiUrl}/files/clear`);
  }
}
