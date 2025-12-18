import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { FragmentationRequest, FragmentationResult } from '../models/fragmentation.model';
import { API_CONFIG } from '../config/api.config';

@Injectable({
  providedIn: 'root'
})
export class FragmentationService {
  private apiUrl = API_CONFIG.apiUrl;

  constructor(private http: HttpClient) { }

  /**
   * Start fragmentation process
   */
  startFragmentation(request?: FragmentationRequest): Observable<FragmentationResult> {
    return this.http.post<FragmentationResult>(
      `${this.apiUrl}/fragmentation/start`,
      request || { cleanAfter: false }
    );
  }
}
