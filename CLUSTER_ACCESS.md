# Guide de Distribution sur le Cluster PQDAG

## Architecture du Cluster

```
Internet
    ↓
Bastion (Jump Host)
193.55.163.204
User: bsaidi
    ↓
Private Network (192.168.165.x)
    ↓
    ├─ Master: 192.168.165.27 (ubuntu)
    └─ Workers (10 machines):
        ├─ 192.168.165.101
        ├─ 192.168.165.138
        ├─ 192.168.165.80
        ├─ 192.168.165.89
        ├─ 192.168.165.126
        ├─ 192.168.165.249
        ├─ 192.168.165.194
        ├─ 192.168.165.46
        ├─ 192.168.165.233
        └─ 192.168.165.63
```

## Connexion SSH avec Jump Host

### Méthode manuelle (avant configuration)
```bash
# Master
ssh -J bsaidi@193.55.163.204 ubuntu@192.168.165.27

# Worker 1
ssh -J bsaidi@193.55.163.204 ubuntu@192.168.165.101
```

### Méthode automatique (après configuration)
```bash
# 1. Configurer SSH une seule fois
./setup-ssh-cluster.sh

# 2. Ensuite, connexion simplifiée
ssh pqdag-master
ssh pqdag-worker-1
ssh pqdag-worker-2
# etc.
```

## Étapes de Configuration

### 1. Configuration SSH (à faire une fois)

```bash
# Configurer les clés SSH et le jump host
./setup-ssh-cluster.sh
```

Ce script va :
- ✅ Générer une clé SSH si nécessaire
- ✅ Configurer `~/.ssh/config` avec le jump host
- ✅ Copier la clé publique vers le bastion
- ✅ Copier la clé publique vers master et workers
- ✅ Tester les connexions

**Note**: Vous devrez entrer :
- Le mot de passe du bastion (`bsaidi`) - 1 fois
- Le mot de passe `ubuntu` pour chaque machine du cluster - 11 fois

### 2. Test de Connectivité

```bash
# Tester l'accès au cluster
./test-distribution.sh
```

Ce script va :
- ✅ Vérifier la configuration SSH
- ✅ Tester la connexion au master
- ✅ Tester la connexion aux workers
- ✅ Vérifier les fichiers d'allocation
- ✅ Simuler la création d'archives
- ✅ Tester le transfert SCP

### 3. Distribution des Fragments (prochaine étape)

```bash
# Distribution réelle (à implémenter)
python3 backend/allocation/distribute_fragments.py \
    --config_file backend/allocation/config_runtime.yaml
```

## Fichiers de Configuration

### `ssh_config_cluster`
Configuration SSH avec aliases pour toutes les machines du cluster.

### `setup-ssh-cluster.sh`
Script d'installation automatique de la configuration SSH.

### `test-distribution.sh`
Script de test de connectivité et préparation des archives.

## Workflow Complet

```
1. Fragmentation ✅
   └─ storage/outputdata/ (918 fragments)

2. Allocation ✅
   ├─ stat_MPI.py → db.stat
   ├─ generate_fragments_graph.py → fragments_graph.quad
   └─ weighted_metis.py → affectation_weighted_metis.txt

3. Configuration SSH 🔄 (à faire)
   └─ ./setup-ssh-cluster.sh

4. Test de Distribution 🔄 (à faire)
   └─ ./test-distribution.sh

5. Distribution Réelle ⏸️ (prochaine étape)
   ├─ Création des archives par worker
   ├─ SCP vers chaque worker
   └─ Extraction sur les workers
```

## Troubleshooting

### Problème: "Permission denied (publickey)"
```bash
# Re-copier la clé SSH
ssh-copy-id -J bsaidi@193.55.163.204 ubuntu@192.168.165.27
```

### Problème: "Connection timeout"
```bash
# Vérifier le VPN/accès réseau au bastion
ping 193.55.163.204

# Tester la connexion au bastion
ssh bsaidi@193.55.163.204
```

### Problème: "Host key verification failed"
```bash
# Nettoyer les clés SSH connues
ssh-keygen -R 193.55.163.204
ssh-keygen -R 192.168.165.27
```

## Sécurité

### Configuration actuelle (développement)
- SSH avec mot de passe via jump host
- StrictHostKeyChecking désactivé (pour faciliter les tests)

### Configuration recommandée (production)
- Clés SSH uniquement (pas de mot de passe)
- StrictHostKeyChecking activé
- Firewall configuré sur le bastion
- VPN pour accès au bastion

## Commandes Utiles

```bash
# Lister toutes les sessions SSH actives
ssh bastion "who"

# Exécuter une commande sur toutes les machines
for i in {1..10}; do
    ssh pqdag-worker-$i "hostname && uptime"
done

# Copier un fichier vers toutes les machines
for i in {1..10}; do
    scp file.txt pqdag-worker-$i:/tmp/
done

# Nettoyer les données de test sur le cluster
ssh pqdag-master "rm -rf /home/ubuntu/mounted_vol/pqdag_temp_data/*"
for i in {1..10}; do
    ssh pqdag-worker-$i "rm -rf /home/ubuntu/mounted_vol/pqdag_temp_data/*"
done
```

## Prochaines Étapes

1. ✅ Créer `ssh_config_cluster`
2. ✅ Créer `setup-ssh-cluster.sh`
3. ✅ Créer `test-distribution.sh`
4. 🔄 Exécuter `./setup-ssh-cluster.sh` (à faire manuellement)
5. 🔄 Tester avec `./test-distribution.sh`
6. ⏸️ Adapter `distribute_fragments.py` pour le jump host
7. ⏸️ Tester la distribution réelle
8. ⏸️ Intégrer dans le GUI
