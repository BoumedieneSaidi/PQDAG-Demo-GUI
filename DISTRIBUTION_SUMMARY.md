# Résumé de la Distribution - Phase 2 : Allocation

## ✅ Configuration SSH Réussie

La configuration SSH avec jump host a été mise en place avec succès :
- **Bastion** : 193.55.163.204 (bsaidi@s-virtualserver7-lias)
- **Master** : 192.168.165.27 (ubuntu@master)
- **10 Workers** : 192.168.165.{101,138,80,89,126,249,194,46,233,63}

### Aliases SSH configurés
```bash
ssh pqdag-master      # Connexion au master
ssh pqdag-worker-1    # Connexion au worker 1
ssh pqdag-worker-2    # Connexion au worker 2
# ... jusqu'à worker-10
```

Tous les workers sont accessibles sans mot de passe grâce aux clés SSH configurées.

---

## ✅ Distribution Complète Réussie

### Statistiques de Distribution

**Dataset** : watdiv100k  
**Total fragments** : 918  
**Workers** : 10  

**Distribution équilibrée (METIS)** :
| Machine | Fragments | Taille Archive |
|---------|-----------|----------------|
| Worker 1 | 89 | 113 KB |
| Worker 2 | 93 | 130 KB |
| Worker 3 | 89 | 113 KB |
| Worker 4 | 94 | 253 KB |
| Worker 5 | 93 | 479 KB |
| Worker 6 | 89 | 133 KB |
| Worker 7 | 89 | 131 KB |
| Worker 8 | 94 | 183 KB |
| Worker 9 | 94 | 914 KB |
| Worker 10 | 94 | 225 KB |

### Pipeline d'Allocation Complet

#### Étape 1 : Calcul des statistiques (MPI)
```bash
mpiexec -n 4 python3 stat_MPI.py /app/storage/outputdata /app/storage/allocation_results/db
```
- ✅ Génération de `db.stat` : 918 lignes, 1.1M
- ✅ Temps d'exécution : ~5.5 secondes avec 4 processus MPI

#### Étape 2 : Génération du graphe de fragments
```bash
python3 generate_fragments_graph.py
```
- ✅ Génération de `fragments_graph.quad` : 87,374 arêtes, 1.1M
- ✅ Format : "source predicate target weight"

#### Étape 3 : Allocation METIS
```bash
python3 weighted_metis.py
```
- ✅ Génération de `affectation_weighted_metis.txt` : 918 allocations
- ✅ Distribution équilibrée : 89-94 fragments par machine

#### Étape 4 : Distribution aux workers
```bash
python3 distribute_fragments.py --config_file config_runtime.yaml
```
- ✅ Création de 10 archives tar.gz (une par worker)
- ✅ Transfert via SCP à travers le jump host
- ✅ Extraction automatique sur chaque worker
- ✅ Chargement dans BTrees (`fragments_loader.py`)
- ✅ Nettoyage automatique des fichiers temporaires

---

## 📁 Structure des Fichiers

### Sur le poste local
```
storage/
├── outputdata/              # 918 fragments du dataset watdiv100k
│   ├── *.data, *.dic, *.schema
│   ├── spo_index.txt
│   ├── ops_index.txt
│   └── predicates.txt
├── allocation_results/      # Résultats de l'allocation
│   ├── db.stat
│   ├── fragments_graph.quad
│   └── affectation_weighted_metis.txt
└── allocation_temp/         # Archives temporaires (nettoyées après)
    └── worker_*.tar.gz
```

### Sur chaque worker
```
/home/ubuntu/pqdag/
├── data/                    # Répertoire temporaire (vide après distribution)
└── storage/                 # Stockage permanent des fragments
    ├── <fragment_id>        # Fichiers BTrees
    ├── <fragment_id>.schema
    └── affectation          # Liste des fragments de ce worker
```

### Sur le master
```
/home/ubuntu/pqdag/data/
├── spo_index.txt
├── ops_index.txt
├── predicates.txt
└── global_affectation.txt   # Affectation globale
```

---

## 🔧 Corrections Effectuées

### 1. Configuration SSH avec Jump Host
- ✅ Fichier `ssh_config_cluster` créé avec ProxyJump
- ✅ Script `setup-ssh-cluster.sh` pour configuration automatique
- ✅ Clés SSH distribuées à tous les nœuds (1 bastion + 1 master + 10 workers)

### 2. Adaptation de `distribute_fragments.py`
- ✅ Utilisation des alias SSH (`pqdag-worker-X`) au lieu d'IPs directes
- ✅ Gestion automatique du jump host via configuration SSH
- ✅ Quotage correct des chemins avec espaces
- ✅ Gestion d'erreurs améliorée

### 3. Configuration Dynamique
- ✅ Template `config.yaml` avec variables `${WORKSPACE_ROOT}` et `${DATASET_NAME}`
- ✅ Script `generate_config.py` pour génération automatique
- ✅ Chemins adaptés au cluster : `/home/ubuntu/pqdag/data/` et `/home/ubuntu/pqdag/storage/`

### 4. Corrections de Bugs
- ✅ Bug path concatenation dans `stat_MPI.py` (lignes 39, 105)
- ✅ Ajout de pandas dans requirements.txt
- ✅ Correction du nom de fichier d'affectation (sans suffixe dataset)

---

## 🎯 Prochaines Étapes

### Phase 2.5 : Backend API Allocation

Créer un endpoint Spring Boot pour l'allocation :

**Endpoint** : `POST /api/allocation/start`

**Request Body** :
```json
{
  "datasetName": "watdiv100k",
  "numMachines": 10,
  "cleanAfter": true
}
```

**Fonctionnalités** :
1. Génération de `config_runtime.yaml`
2. Exécution de `stat_MPI.py` via Docker
3. Exécution de `generate_fragments_graph.py`
4. Exécution de `weighted_metis.py`
5. Retour des statistiques et résultats

**Response** :
```json
{
  "status": "success",
  "statistics": {
    "totalFragments": 918,
    "totalEdges": 87374,
    "executionTime": "12.5s"
  },
  "distribution": [
    {"machine": 1, "fragments": 89},
    {"machine": 2, "fragments": 93},
    ...
  ]
}
```

### Phase 3 : Frontend Allocation GUI

**Component** : `AllocationComponent`

**Features** :
- Configuration : nombre de machines, dataset
- Gestion Master/Workers IPs
- Bouton "Start Allocation" avec loading state
- Indicateurs de progression (steps 1-4)
- Affichage des résultats :
  - Graphique de distribution (bar chart)
  - Table de statistiques
  - Bouton de téléchargement du fichier d'affectation
- Intégration avec FragmentationComponent

### Phase 4 : Distribution GUI

**Endpoint** : `POST /api/allocation/distribute`

**Features** :
- Bouton "Distribute to Cluster"
- Validation SSH avant distribution
- Barre de progression par worker
- Logs en temps réel (WebSocket optionnel)
- Vérification post-distribution

---

## 📊 Métriques de Performance

### Allocation (local)
- **Étape 1 (MPI Statistics)** : ~5.5 secondes (4 processus)
- **Étape 2 (Graph Generation)** : ~2 secondes
- **Étape 3 (METIS Allocation)** : ~1 seconde
- **Total** : ~8.5 secondes pour 918 fragments

### Distribution (cluster via jump host)
- **Création des archives** : ~2 secondes (parallèle)
- **Transfert Worker 1** : ~1 seconde (113 KB)
- **Transfert Worker 9** : ~5 secondes (914 KB)
- **Chargement BTrees** : 1.7-3.1 secondes par worker
- **Total** : ~25-30 secondes pour 10 workers

---

## 🔒 Sécurité

### SSH
- ✅ Clés SSH 4096 bits RSA
- ✅ Authentification par clé (pas de mot de passe)
- ✅ Jump host (bastion) pour accès cluster
- ✅ StrictHostKeyChecking désactivé pour le cluster privé

### Réseau
- ✅ Cluster sur réseau privé (192.168.165.0/24)
- ✅ Accès uniquement via bastion (193.55.163.204)
- ✅ Pas d'exposition directe des workers

---

## 📝 Scripts de Test

### `test-allocation-simple.sh`
Teste les 3 premières étapes de l'allocation (sans distribution).

### `test-distribution.sh`
Teste la connectivité et la préparation sans vraie distribution.

### `test-distribution-real.sh`
**Vraie distribution** complète vers le cluster (avec confirmation).

### Exécution
```bash
# Allocation seulement
./test-allocation-simple.sh

# Test de connectivité
./test-distribution.sh

# Distribution réelle
./test-distribution-real.sh
```

---

## ✅ Validation

Tous les tests ont réussi :
- ✅ 10/10 workers accessibles
- ✅ Master accessible
- ✅ Archives créées et transférées
- ✅ Fragments extraits sur chaque worker
- ✅ BTrees chargés avec succès
- ✅ Distribution équilibrée validée (89-94 fragments/machine)

**Date de validation** : 16 décembre 2024  
**Status** : Phase 2 (Allocation) ✅ COMPLÈTE
