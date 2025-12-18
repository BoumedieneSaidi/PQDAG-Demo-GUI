import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FileService } from '../../services/file.service';

@Component({
  selector: 'app-file-upload',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './file-upload.component.html',
  styleUrl: './file-upload.component.scss'
})
export class FileUploadComponent {
  selectedFiles: File[] = [];
  isDragging = false;
  uploadProgress = false;
  uploadResult: any = null;
  errorMessage = '';

  constructor(private fileService: FileService) {}

  onFileSelected(event: any) {
    const files: FileList = event.target.files;
    this.addFiles(files);
  }

  onDragOver(event: DragEvent) {
    event.preventDefault();
    event.stopPropagation();
    this.isDragging = true;
  }

  onDragLeave(event: DragEvent) {
    event.preventDefault();
    event.stopPropagation();
    this.isDragging = false;
  }

  onDrop(event: DragEvent) {
    event.preventDefault();
    event.stopPropagation();
    this.isDragging = false;
    
    const files = event.dataTransfer?.files;
    if (files) {
      this.addFiles(files);
    }
  }

  addFiles(files: FileList) {
    this.errorMessage = '';
    for (let i = 0; i < files.length; i++) {
      const file = files[i];
      if (this.isValidFile(file)) {
        this.selectedFiles.push(file);
      } else {
        this.errorMessage = `Invalid file: ${file.name}. Only .nt and .ttl files are allowed.`;
      }
    }
  }

  isValidFile(file: File): boolean {
    const validExtensions = ['.nt', '.ttl'];
    return validExtensions.some(ext => file.name.toLowerCase().endsWith(ext));
  }

  removeFile(index: number) {
    this.selectedFiles.splice(index, 1);
  }

  clearAll() {
    this.selectedFiles = [];
    this.uploadResult = null;
    this.errorMessage = '';
  }

  uploadFiles() {
    if (this.selectedFiles.length === 0) {
      this.errorMessage = 'Please select at least one file.';
      return;
    }

    this.uploadProgress = true;
    this.errorMessage = '';
    
    const fileList = this.createFileList(this.selectedFiles);
    
    this.fileService.uploadFiles(fileList).subscribe({
      next: (response) => {
        this.uploadProgress = false;
        this.uploadResult = response;
        this.selectedFiles = [];
      },
      error: (error) => {
        this.uploadProgress = false;
        this.errorMessage = error.error?.message || 'Upload failed. Please try again.';
      }
    });
  }

  private createFileList(files: File[]): FileList {
    const dataTransfer = new DataTransfer();
    files.forEach(file => dataTransfer.items.add(file));
    return dataTransfer.files;
  }

  formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
  }
}
