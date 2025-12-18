# Test Upload API

## 1. Test Health Endpoint
```bash
curl http://localhost:8080/api/health
```

## 2. List files in rawdata (should be empty initially)
```bash
curl http://localhost:8080/api/files/list
```

## 3. Upload a file
```bash
curl -X POST http://localhost:8080/api/files/upload \
  -F "files=@/home/boumi/Documents/PQDAG GUI/storage/rawdata/watdiv100k.nt"
```

## 4. List files again (should show uploaded file)
```bash
curl http://localhost:8080/api/files/list
```

## 5. Clear rawdata
```bash
curl -X DELETE http://localhost:8080/api/files/clear
```
