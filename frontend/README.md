# PQDAG Fragmentation GUI - Frontend# Frontend



Angular web application for PQDAG RDF fragmentation management.This project was generated with [Angular CLI](https://github.com/angular/angular-cli) version 18.2.21.



## 🚀 Features## Development server



- **Drag & Drop Upload**: Upload RDF files (.nt, .ttl) with visual feedbackRun `ng serve` for a dev server. Navigate to `http://localhost:4200/`. The application will automatically reload if you change any of the source files.

- **Real-time Metrics**: View fragmentation statistics and performance metrics

- **Phase Breakdown**: Detailed timing analysis for each fragmentation phase## Code scaffolding

- **Clean UI**: Modern gradient design with responsive layout

- **API Integration**: Seamless communication with Spring Boot backendRun `ng generate component component-name` to generate a new component. You can also use `ng generate directive|pipe|service|class|guard|interface|enum|module`.



## 📋 Prerequisites## Build



- **Node.js**: 18.x or higherRun `ng build` to build the project. The build artifacts will be stored in the `dist/` directory.

- **npm**: 9.x or higher

- **Angular CLI**: 18.x (`npm install -g @angular/cli`)## Running unit tests



## 🛠️ InstallationRun `ng test` to execute the unit tests via [Karma](https://karma-runner.github.io).



1. **Install dependencies**:## Running end-to-end tests

```bash

cd frontendRun `ng e2e` to execute the end-to-end tests via a platform of your choice. To use this command, you need to first add a package that implements end-to-end testing capabilities.

npm install

```## Further help



## 🏃 Running the ApplicationTo get more help on the Angular CLI use `ng help` or go check out the [Angular CLI Overview and Command Reference](https://angular.dev/tools/cli) page.


### Development Server

```bash
ng serve
```

Navigate to `http://localhost:4200/`. The application will automatically reload if you change any source files.

### Development Server with Auto-Open

```bash
ng serve --open
```

### Production Build

```bash
ng build --configuration production
```

The build artifacts will be stored in the `dist/` directory.

## 🏗️ Project Structure

```
frontend/
├── src/
│   ├── app/
│   │   ├── components/           # UI Components
│   │   │   ├── file-upload/      # Drag & drop file upload
│   │   │   └── fragmentation-results/  # Metrics dashboard
│   │   ├── services/             # HTTP Services
│   │   │   ├── file.service.ts
│   │   │   └── fragmentation.service.ts
│   │   ├── models/               # TypeScript Interfaces
│   │   │   └── fragmentation.model.ts
│   │   ├── config/               # Configuration
│   │   │   └── api.config.ts
│   │   ├── app.component.*       # Root component
│   │   ├── app.config.ts         # App configuration
│   │   └── app.routes.ts         # Routing configuration
│   ├── styles.scss               # Global styles
│   └── index.html
├── angular.json                  # Angular workspace config
├── package.json                  # Dependencies
└── tsconfig.json                 # TypeScript config
```

## 🔌 Backend Configuration

The frontend expects the backend API to be running on `http://localhost:8080/api`.

To change the API URL, edit `src/app/config/api.config.ts`:

```typescript
export const API_CONFIG = {
  apiUrl: 'http://your-backend-url:port/api'
};
```

## 📊 Usage Workflow

1. **Start Backend**: Make sure Spring Boot API is running on port 8080
2. **Start Frontend**: Run `ng serve` and open http://localhost:4200
3. **Upload Files**: Drag & drop your .nt or .ttl files
4. **Upload**: Click "Upload Files" button
5. **Configure**: Check/uncheck "Clean after fragmentation"
6. **Fragment**: Click "Start Fragmentation"
7. **View Results**: See metrics, fragment count, and phase timings

## 🎨 Components

### FileUploadComponent
- Drag & drop interface
- File validation (.nt, .ttl only)
- File list with sizes
- Remove individual files
- Upload progress

### FragmentationResultsComponent
- Key metrics cards (fragments, triples, time, throughput)
- Phase breakdown with progress bars
- Color-coded phases:
  - 🔵 Data Encoding
  - 🟢 Dictionaries
  - 🟠 Sorting
  - 🟣 Fragmentation
  - 🔴 Re-encoding

## 🛠️ Development

### Code Scaffolding

Generate new component:
```bash
ng generate component components/my-component
```

Generate new service:
```bash
ng generate service services/my-service
```

### Running Unit Tests

```bash
ng test
```

## 📦 Dependencies

- **@angular/common**: Angular common module
- **@angular/core**: Angular core framework
- **@angular/platform-browser**: Browser platform
- **rxjs**: Reactive extensions
- **tslib**: TypeScript runtime library

## 🎯 API Integration

### Services

#### FileService
```typescript
uploadFiles(files: FileList): Observable<UploadResponse>
listFiles(): Observable<any>
clearFiles(): Observable<any>
```

#### FragmentationService
```typescript
startFragmentation(request: FragmentationRequest): Observable<FragmentationResult>
```

### Models

#### FragmentationRequest
```typescript
interface FragmentationRequest {
  cleanAfter: boolean;
}
```

#### FragmentationResult
```typescript
interface FragmentationResult {
  success: boolean;
  message: string;
  fragmentCount: number;
  totalTriples: number;
  executionTimeSeconds: number;
  throughput: number;
  encodingTime?: number;
  dictionariesTime?: number;
  sortingTime?: number;
  fragmentationTime?: number;
  reencodingTime?: number;
  dockerOutput?: string;
}
```

## 🚧 Future Enhancements

- [ ] WebSocket integration for live Docker logs
- [ ] File upload progress tracking
- [ ] Fragment visualization
- [ ] Export metrics to CSV/JSON
- [ ] Dark mode theme

## 🐛 Troubleshooting

### Port 4200 already in use
```bash
# Kill existing processes
pkill -9 -f "ng serve"
pkill -9 node
fuser -k 4200/tcp
```

### Backend not responding
1. Check backend is running on port 8080
2. Test with: `curl http://localhost:8080/api/health`
3. Check CORS configuration in backend

### Upload fails
1. Verify file format (.nt or .ttl)
2. Check file size (max 1GB)
3. Ensure backend storage directories exist

## 📄 License

Part of PQDAG-Demo-GUI project.

## 👥 Authors

- BoumedieneSaidi

## 🔗 Related

- [Backend API Documentation](../backend/api/README.md)
- [Fragmentation Engine](../backend/fragmentation/README.md)
- [Project Context](../CONTEXT.md)
