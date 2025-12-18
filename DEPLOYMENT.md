# Guide de Déploiement - PQDAG GUI sur le Cluster

## Vue d'ensemble

Ce guide explique comment déployer l'application PQDAG GUI complète sur le nœud master du cluster pour un accès centralisé.

## Architecture de Déploiement

```
┌─────────────────────────────────────────────────────────┐
│                    Internet                              │
│                       ↓                                  │
│              Bastion (Jump Host)                         │
│              193.55.163.204:22                           │
│                       ↓                                  │
│              ┌────────────────┐                          │
│              │  Master Node   │                          │
│              │  192.168.165.27│                          │
│              │                │                          │
│              │  ┌──────────┐  │                          │
│              │  │ Frontend │◄─┼──── Port 80 (HTTP)       │
│              │  │ (nginx)  │  │                          │
│              │  └──────────┘  │                          │
│              │       ↓         │                          │
│              │  ┌──────────┐  │                          │
│              │  │ Backend  │◄─┼──── Port 8080 (API)      │
│              │  │ (Spring) │  │                          │
│              │  └──────────┘  │                          │
│              │       ↓         │                          │
│              │  ┌──────────┐  │                          │
│              │  │Allocation│  │                          │
│              │  │(Python+  │  │                          │
│              │  │  MPI)    │  │                          │
│              │  └──────────┘  │                          │
│              │       ↓         │                          │
│              │  /mounted_vol/  │                          │
│              │   pqdag_data    │                          │
│              └────────┬────────┘                          │
│                       ↓                                  │
│              ┌────────────────┐                          │
│              │ 10 Worker Nodes│                          │
│              │ (192.168.165.x)│                          │
│              └────────────────┘                          │
└─────────────────────────────────────────────────────────┘
```

## Prérequis

### Sur votre machine locale

1. **Configuration SSH**
   ```bash
   ./setup-ssh-cluster.sh
   ```
   Cela configure les alias SSH pour accès simplifié au cluster.

2. **Connexion au master vérifiée**
   ```bash
   ssh pqdag-master
   ```

### Sur le master (automatiquement installé par le script)

- Docker
- Docker Compose
- Accès aux workers via SSH sans mot de passe

## Déploiement Automatique

### Méthode simple (recommandée)

```bash
# 1. Rendre le script exécutable
chmod +x deploy-to-master.sh

# 2. Lancer le déploiement
./deploy-to-master.sh
```

Le script va :
1. ✅ Vérifier la connectivité SSH
2. ✅ Installer Docker si nécessaire
3. ✅ Créer la structure de répertoires
4. ✅ Transférer les fichiers de l'application
5. ✅ Configurer l'environnement du master
6. ✅ Construire les images Docker
7. ✅ Démarrer tous les services

### Durée estimée
- Première fois: ~10-15 minutes (build des images)
- Déploiements suivants: ~3-5 minutes

## Déploiement Manuel

Si vous préférez un contrôle total, voici les étapes manuelles :

### 1. Préparer le master

```bash
# Connexion au master
ssh pqdag-master

# Créer les répertoires
mkdir -p /home/ubuntu/pqdag-gui
mkdir -p /home/ubuntu/pqdag-gui/storage/{rawdata,bindata,outputdata,allocation_results,allocation_temp}
```

### 2. Transférer les fichiers

```bash
# Sur votre machine locale
# Créer une archive (exclure node_modules, .git, etc.)
tar -czf pqdag-gui.tar.gz \
    --exclude='node_modules' \
    --exclude='.git' \
    --exclude='storage/*' \
    --exclude='backend/api/target' \
    --exclude='*.log' \
    .

# Transférer au master
scp pqdag-gui.tar.gz pqdag-master:/tmp/

# Sur le master
ssh pqdag-master
cd /home/ubuntu/pqdag-gui
tar -xzf /tmp/pqdag-gui.tar.gz
rm /tmp/pqdag-gui.tar.gz
```

### 3. Configurer les IPs des workers

```bash
# Sur le master
cat > /home/ubuntu/pqdag-gui/backend/allocation/workers <<EOF
192.168.165.101
192.168.165.138
192.168.165.80
192.168.165.89
192.168.165.126
192.168.165.249
192.168.165.194
192.168.165.46
192.168.165.233
192.168.165.63
EOF
```

### 4. Créer docker-compose.override.yml

```bash
cat > /home/ubuntu/pqdag-gui/docker-compose.override.yml <<EOF
version: '3.8'

services:
  api:
    ports:
      - "8080:8080"
    volumes:
      - /home/ubuntu/mounted_vol/pqdag_data:/app/storage
    restart: always

  allocation:
    volumes:
      - /home/ubuntu/mounted_vol/pqdag_data:/app/storage
      - ~/.ssh:/home/pqdag/.ssh:ro
    restart: always

  frontend:
    ports:
      - "80:80"
    restart: always
EOF
```

### 5. Construire et démarrer

```bash
cd /home/ubuntu/pqdag-gui

# Build des images
docker-compose build

# Démarrer les services
docker-compose up -d

# Vérifier le status
docker-compose ps
```

## Accès à l'Application

### Depuis le réseau local du cluster

```
Frontend: http://192.168.165.27
Backend:  http://192.168.165.27:8080
```

### Depuis votre machine (via tunnel SSH)

```bash
# Terminal 1: Tunnel pour frontend
ssh -L 8081:192.168.165.27:80 pqdag-master

# Terminal 2: Tunnel pour backend
ssh -L 8080:192.168.165.27:8080 pqdag-master

# Accès via navigateur
Frontend: http://localhost:8081
Backend:  http://localhost:8080
```

### Depuis Internet (si bastion expose les ports)

Si le bastion est configuré pour faire du port forwarding :
```
Frontend: http://193.55.163.204:8081
Backend:  http://193.55.163.204:8080
```

## Gestion des Services

### Voir les logs

```bash
ssh pqdag-master
cd /home/ubuntu/pqdag-gui

# Tous les services
docker-compose logs -f

# Service spécifique
docker-compose logs -f api
docker-compose logs -f frontend
docker-compose logs -f allocation
```

### Redémarrer les services

```bash
# Redémarrage complet
docker-compose restart

# Service spécifique
docker-compose restart api
```

### Arrêter les services

```bash
docker-compose down
```

### Mettre à jour l'application

```bash
# 1. Sur votre machine locale, créer une nouvelle archive
./deploy-to-master.sh

# Ou manuellement :
# 2. Sur le master
ssh pqdag-master
cd /home/ubuntu/pqdag-gui
docker-compose down
git pull  # Si vous avez cloné le dépôt
docker-compose build
docker-compose up -d
```

## Structure des Répertoires sur le Master

```
/home/ubuntu/
├── pqdag-gui/                    # Application déployée
│   ├── backend/
│   │   ├── api/                  # Spring Boot backend
│   │   └── allocation/           # Python allocation service
│   ├── frontend/                 # Angular frontend
│   ├── docker-compose.yml
│   ├── docker-compose.override.yml
│   └── storage/                  # Liens vers mounted_vol
│       ├── rawdata/
│       ├── bindata/
│       ├── outputdata/
│       ├── allocation_results/
│       └── allocation_temp/
│
└── mounted_vol/                  # Stockage partagé
    └── pqdag_data/               # Données RDF et fragments
        ├── watdiv100k/
        └── ...
```

## Vérification du Déploiement

### 1. Vérifier que tous les conteneurs tournent

```bash
ssh pqdag-master
cd /home/ubuntu/pqdag-gui
docker-compose ps
```

Résultat attendu :
```
NAME                    COMMAND                  SERVICE             STATUS
pqdag-allocation        "tail -f /dev/null"      allocation          running
pqdag-api               "java -jar app.jar"      api                 running
pqdag-frontend          "nginx -g 'daemon of…"   frontend            running
```

### 2. Tester le frontend

```bash
# Depuis le master
curl http://localhost

# Depuis votre machine (avec tunnel)
curl http://localhost:8081
```

### 3. Tester le backend

```bash
# Health check
curl http://192.168.165.27:8080/api/health

# Ou via tunnel
curl http://localhost:8080/api/health
```

### 4. Tester l'allocation

```bash
ssh pqdag-master
cd /home/ubuntu/pqdag-gui

# Vérifier que le service allocation peut exécuter MPI
docker-compose exec allocation mpiexec --version
```

## Troubleshooting

### Les conteneurs ne démarrent pas

```bash
# Voir les logs d'erreur
docker-compose logs

# Vérifier l'espace disque
df -h

# Vérifier les ports utilisés
sudo netstat -tulpn | grep -E ':(80|8080)'
```

### Le frontend ne charge pas

```bash
# Reconstruire le frontend
docker-compose build frontend
docker-compose up -d frontend

# Vérifier les logs nginx
docker-compose logs frontend
```

### Le backend ne répond pas

```bash
# Vérifier les logs Java
docker-compose logs api

# Vérifier que le port 8080 est accessible
curl http://192.168.165.27:8080/api/health
```

### Problèmes de connexion aux workers

```bash
# Vérifier que les clés SSH sont montées
docker-compose exec allocation ls -la /home/pqdag/.ssh/

# Tester une connexion depuis le conteneur allocation
docker-compose exec allocation ssh ubuntu@192.168.165.101 "hostname"
```

## Sécurité

### Recommandations

1. **Firewall sur le master**
   ```bash
   # Autoriser seulement les connexions depuis le bastion
   sudo ufw allow from 193.55.163.204 to any port 80
   sudo ufw allow from 193.55.163.204 to any port 8080
   ```

2. **Pas d'exposition directe**
   - Ne pas exposer les ports 80/8080 du master sur Internet
   - Utiliser le bastion comme seul point d'entrée

3. **Authentification**
   - Ajouter une authentification (Basic Auth, JWT) dans nginx si nécessaire
   - Limiter l'accès par IP

### Configuration nginx avec authentification (optionnel)

```nginx
# Dans frontend/nginx.conf
location / {
    auth_basic "PQDAG GUI";
    auth_basic_user_file /etc/nginx/.htpasswd;
    try_files $uri $uri/ /index.html;
}
```

## Sauvegarde et Restauration

### Sauvegarder les données

```bash
ssh pqdag-master

# Sauvegarder les fragments et résultats
tar -czf /tmp/pqdag-backup-$(date +%Y%m%d).tar.gz \
    /home/ubuntu/mounted_vol/pqdag_data

# Transférer la sauvegarde
scp pqdag-master:/tmp/pqdag-backup-*.tar.gz ./backups/
```

### Restaurer les données

```bash
# Transférer la sauvegarde au master
scp ./backups/pqdag-backup-20231216.tar.gz pqdag-master:/tmp/

# Sur le master
ssh pqdag-master
cd /home/ubuntu/mounted_vol
tar -xzf /tmp/pqdag-backup-20231216.tar.gz
```

## Monitoring

### Métriques des conteneurs

```bash
# Utilisation ressources
docker stats

# Logs en temps réel
docker-compose logs -f --tail=100
```

### Logs applicatifs

```bash
# Backend (Spring Boot)
docker-compose logs -f api | grep ERROR

# Allocation (Python)
docker-compose logs -f allocation

# Frontend (nginx access logs)
docker-compose logs -f frontend
```

## Performance

### Optimisations recommandées

1. **Augmenter la mémoire Java**
   ```yaml
   # docker-compose.override.yml
   services:
     api:
       environment:
         - JAVA_OPTS=-Xmx4g -Xms2g
   ```

2. **Configurer nginx cache**
   ```nginx
   # frontend/nginx.conf
   proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=api_cache:10m;
   ```

3. **Limiter les processus MPI**
   ```yaml
   services:
     allocation:
       environment:
         - MPI_PROCESSES=8
   ```

## Support

Pour toute question ou problème :

1. Vérifier les logs : `docker-compose logs`
2. Consulter la documentation : `README.md`, `PIPELINE_GUIDE.md`
3. Vérifier les issues GitHub

---

**Note** : Ce guide suppose que le master a accès au volume monté `/home/ubuntu/mounted_vol/pqdag_data` partagé avec les workers.
