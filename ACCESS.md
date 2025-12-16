# Accès à PQDAG GUI sur le Master

Le master (192.168.165.27) est dans un réseau privé accessible uniquement via le bastion jump host. Voici les différentes options pour accéder à l'interface web.

## 🔒 Option 1 : SSH Tunnel (Recommandé)

### Méthode rapide :
```bash
./tunnel-to-master.sh
```

Puis ouvrez votre navigateur sur :
- **Frontend** : http://localhost:8000
- **Backend** : http://localhost:8080

### Méthode manuelle :
```bash
ssh -L 8000:192.168.165.27:80 -L 8080:192.168.165.27:8080 -J bsaidi@193.55.163.204 ubuntu@192.168.165.27
```

**Mot de passe** : `bsaidi`

Le tunnel restera actif tant que la connexion SSH est ouverte. Appuyez sur `Ctrl+C` pour l'arrêter.

---

## 🖥️ Option 2 : Accès direct depuis un Worker

Si vous êtes connecté à un des workers du cluster, vous pouvez accéder directement :

```bash
# SSH vers un worker
ssh -J bsaidi@193.55.163.204 ubuntu@192.168.165.101

# Puis accéder au master
curl http://192.168.165.27        # Frontend
curl http://192.168.165.27:8080   # Backend
```

Ou installer un navigateur en mode texte :
```bash
lynx http://192.168.165.27
```

---

## 🌐 Option 3 : Reverse Proxy sur le Bastion (Configuration avancée)

Si vous avez accès administrateur au bastion, vous pouvez configurer nginx comme reverse proxy :

```nginx
# Sur le bastion (193.55.163.204)
server {
    listen 80;
    server_name pqdag.example.com;
    
    location / {
        proxy_pass http://192.168.165.27:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    location /api/ {
        proxy_pass http://192.168.165.27:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## 📊 Vérifier l'état des services

### Depuis votre machine locale :
```bash
# Via SSH
ssh -J bsaidi@193.55.163.204 ubuntu@192.168.165.27 \
  "cd ~/mounted_vol/pqdag-gui && docker-compose ps"

# Voir les logs
ssh -J bsaidi@193.55.163.204 ubuntu@192.168.165.27 \
  "cd ~/mounted_vol/pqdag-gui && docker-compose logs -f"
```

### Depuis le master :
```bash
cd ~/mounted_vol/pqdag-gui
docker-compose ps
docker-compose logs -f
```

---

## 🔧 Gestion des services

### Redémarrer :
```bash
ssh -J bsaidi@193.55.163.204 ubuntu@192.168.165.27 \
  "cd ~/mounted_vol/pqdag-gui && docker-compose restart"
```

### Arrêter :
```bash
ssh -J bsaidi@193.55.163.204 ubuntu@192.168.165.27 \
  "cd ~/mounted_vol/pqdag-gui && docker-compose down"
```

### Démarrer :
```bash
ssh -J bsaidi@193.55.163.204 ubuntu@192.168.165.27 \
  "cd ~/mounted_vol/pqdag-gui && docker-compose up -d"
```

---

## 💡 Configuration SSH (Optionnel)

Pour simplifier l'accès, ajoutez cette configuration dans `~/.ssh/config` :

```
# Bastion
Host bastion
    HostName 193.55.163.204
    User bsaidi
    
# Master via bastion
Host pqdag-master
    HostName 192.168.165.27
    User ubuntu
    ProxyJump bastion
```

Puis vous pourrez simplement faire :
```bash
ssh pqdag-master
```

---

## 🚀 Accès rapide recommandé

**Pour développement/test** :
1. Lancez le tunnel : `./tunnel-to-master.sh`
2. Ouvrez http://localhost:8000
3. Utilisez l'interface normalement

**Pour production** :
- Configurez un reverse proxy sur le bastion
- Ou utilisez un VPN pour accéder au réseau privé 192.168.165.0/24
