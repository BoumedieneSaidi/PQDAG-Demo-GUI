# Storage Directory Structure

This directory contains all data files for the PQDAG system.

## Directories

### `rawdata/`
Contains the original RDF datasets to be processed.
- Input files: `.nt` or `.ttl` format
- Example: `watdiv100k.nt`

### `bindata/`
Contains binary encoded data generated during fragmentation.
- Created by the FastEncoder
- Used as intermediate format for fragment generation

### `outputdata/`
Contains the generated fragments and index files from fragmentation.
- Fragment files: `*.data`, `*.dic`, `*.schema`
- Index files: `spo_index.txt`, `ops_index.txt`, `predicates.txt`
- These files are used as input for the allocation step

### `allocation_temp/` (temporary)
Temporary directory for assembling fragment files per worker during allocation.
- Created during distribution process
- Contains tar archives before sending to cluster
- **Automatically cleaned after distribution**
- This folder is git-ignored

### `allocation_results/`
Contains allocation result files.
- `affectation_weighted_metis_<dataset>.txt` - Fragment-to-worker mapping
- `db.stat` - Fragment statistics
- `fragments_graph.quad` - Fragment relationship graph
- These files are persistent and can be reused

## Workflow

```
1. Fragmentation:
   rawdata/*.nt → bindata/ → outputdata/{*.data, *.dic, *.schema, *_index.txt}

2. Allocation:
   outputdata/ → allocation_results/{db.stat, fragments_graph.quad, affectation.txt}
                ↓
            allocation_temp/ (temporary tar archives)
                ↓
            Cluster distribution (SSH/SCP to workers)
```

## Dynamic Configuration

The `config.yaml` file uses variables that are replaced at runtime:
- `${WORKSPACE_ROOT}` - Project root directory
- `${DATASET_NAME}` - Current dataset being processed

This allows the system to work on any machine without hardcoded paths.
