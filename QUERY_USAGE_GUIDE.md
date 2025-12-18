# Guide d'Utilisation - Exécution de Requêtes

## Accès à l'Interface

1. Ouvrez votre navigateur à l'adresse: **http://localhost:4200**
2. Cliquez sur l'onglet **"🔍 Query Execution"** dans la navigation principale

## Étapes d'Utilisation

### 1️⃣ Configurer le Dataset PQDAG

Le dataset PQDAG détermine les données sur lesquelles les requêtes seront exécutées.

1. Dans la section **"Dataset Configuration"**
2. Sélectionnez un dataset dans le menu déroulant (ex: `watdiv100k`, `lubm100m`)
3. Cliquez sur **"Set Dataset"**
4. Attendez le message de confirmation ✅

**Note**: Cette opération met à jour le fichier `config.properties` sur le master et tous les workers (11 nœuds au total).

### 2️⃣ Démarrer le Cluster

Avant d'exécuter des requêtes, le cluster PQDAG doit être démarré.

1. Dans la section **"Cluster Management"**
2. Cliquez sur **"▶ Start Cluster"**
3. Attendez que le statut passe à "running" (environ 10-15 secondes)

**Boutons disponibles**:
- **▶ Start**: Démarre le cluster (master + 10 workers)
- **⏹ Stop**: Arrête tous les nœuds
- **🔄 Restart**: Redémarre complètement le cluster

### 3️⃣ Sélectionner une Requête

1. Dans la section **"Query Execution"**
2. **Query Dataset**: Sélectionnez le dossier de requêtes (ex: `watdiv`)
3. **Query File**: Choisissez le fichier de requête (ex: `C2.in`, `C3.in`, `S3.in`)
4. **Plan Number**: Laissez à 0 (par défaut) ou modifiez selon vos besoins

### 4️⃣ Exécuter la Requête

1. Cliquez sur **"▶ Execute Query"**
2. L'interface affiche:
   - ⏱️ **Execution Time**: Temps d'exécution en millisecondes
   - 📊 **Result Count**: Nombre de résultats retournés
   - 📝 **Query Output**: Résultats complets de la requête

## Exemples de Scénarios

### Scénario 1: Exécution Simple

```
1. Set Dataset: watdiv100k
2. Start Cluster
3. Query Dataset: watdiv
4. Query File: C2.in
5. Execute Query
```

### Scénario 2: Changement de Dataset

```
1. Stop Cluster (si en cours d'exécution)
2. Set Dataset: lubm100m
3. Start Cluster
4. Query Dataset: watdiv
5. Query File: S3.in
6. Execute Query
```

### Scénario 3: Tests Multiples

```
1. Set Dataset: watdiv100k
2. Start Cluster
3. Exécuter C2.in → Noter les résultats
4. Exécuter C3.in → Comparer
5. Exécuter S3.in → Analyser
```

## Datasets Disponibles

### PQDAG Datasets (27 disponibles)
- `watdiv100k` - WatDiv 100K triples
- `watdiv100m` - WatDiv 100M triples
- `watdiv1b` - WatDiv 1B triples
- `lubm100m` - LUBM 100M triples
- `lubm500m` - LUBM 500M triples
- `bio2rdf` - Bio2RDF dataset
- `yago` - YAGO dataset
- Et 20 autres variants...

### Query Datasets (2 disponibles)
- `watdiv` - Requêtes WatDiv
- `watdiv_queries` - Requêtes WatDiv alternatives

## Messages d'État

### ✅ Succès
- "Dataset updated successfully on all nodes"
- "Cluster started successfully"
- "Query executed successfully"

### ❌ Erreurs
- "Failed to update dataset" → Vérifier la connectivité SSH
- "Cluster start failed" → Vérifier les logs avec `docker logs pqdag-api`
- "Query file not found" → Vérifier le chemin du fichier de requête

### ⚠️ Avertissements
- "Cluster is already running" → Pas besoin de redémarrer
- "No cluster status available" → Démarrer le cluster d'abord

## Dépannage

### Le cluster ne démarre pas
```bash
# Vérifier les logs du backend
docker logs pqdag-api --tail 50

# Vérifier la connectivité SSH
docker exec pqdag-api ssh -i /tmp/.ssh/pqdag ubuntu@172.17.0.1 "echo OK"
```

### Le dataset ne se met pas à jour
```bash
# Vérifier sur le master
ssh -i ~/.ssh/pqdag ubuntu@192.168.165.27 "grep DB_DEFAULT ~/pqdag/conf/config.properties"

# Vérifier sur un worker
ssh -i ~/.ssh/pqdag ubuntu@192.168.165.101 "grep DB_DEFAULT ~/pqdag/conf/config.properties"
```

### Les requêtes échouent
```bash
# Vérifier que le fichier de requête existe
ls -la /home/ubuntu/mounted_vol/pqdag-gui/storage/queries/watdiv/

# Vérifier le dataset PQDAG
ls -la /home/ubuntu/mounted_vol/pqdag_data/watdiv100k/
```

## API Endpoints (pour tests)

```bash
# Lister les datasets PQDAG
curl http://localhost:8080/api/query/pqdag-datasets

# Obtenir le dataset actuel
curl http://localhost:8080/api/query/current-dataset

# Changer le dataset
curl -X POST http://localhost:8080/api/query/set-dataset/watdiv100m

# Démarrer le cluster
curl -X POST http://localhost:8080/api/query/start-cluster

# Exécuter une requête
curl -X POST http://localhost:8080/api/query/execute \
  -H "Content-Type: application/json" \
  -d '{
    "dataset": "watdiv",
    "queryFile": "C2.in",
    "planNumber": 0
  }'
```

## Architecture Technique

### Composants
- **Frontend**: Angular 18 avec Material Design
- **Backend**: Spring Boot REST API
- **Cluster**: 1 master + 10 workers PQDAG
- **Communication**: SSH avec clé `~/.ssh/pqdag`

### Flux de Données
```
User → Frontend → API → SSH → Cluster → Results → API → Frontend → User
```

### Fichiers Importants
- Config: `~/pqdag/conf/config.properties`
- Queries: `/home/ubuntu/mounted_vol/pqdag-gui/storage/queries/`
- Data: `/home/ubuntu/mounted_vol/pqdag_data/`

---

**Bon test! Profitez de la nouvelle fonctionnalité! 🚀**
