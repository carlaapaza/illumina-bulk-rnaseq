#!/bin/bash
set -euo pipefail

# ============================================================
# Script: 2_salmon.sh
# Purpose: Build Salmon index (no decoys) and quantify paired-end RNA-seq reads
# Pipeline:
#   transcriptome.fna → salmon index
#   *_R1.clean.fastq.gz + *_R2.clean.fastq.gz → salmon quant (per sample)
# Notes:
#   - Skips indexing if index already exists
#   - Assumes paired-end reads with suffix: *_R1.clean.fastq.gz / *_R2.clean.fastq.gz
# Author: Carla Apaza (Pig Brain NCC project)
# ============================================================

source "$(conda info --base)/etc/profile.d/conda.sh"

# ── Paths ──────────────────────────────────────────────────
TRANSCRIPTOME="resources/reference/rna.fna"
INDEX_DIR="results/2_salmon/index"
READS_DIR="results/1_trimming"
QUANT_DIR="results/2_salmon/quant"

# ── Activate Salmon environment ────────────────────────────
conda activate salmon

# 1) Build index if missing
if [[ ! -d "$INDEX_DIR" ]]; then
  echo "Building Salmon index at $INDEX_DIR..."
  salmon index \
    -t "$TRANSCRIPTOME" \
    -i "$INDEX_DIR" \
    -k 31
  echo "Index built successfully."
else
  echo "Index directory already exists; skipping indexing."
fi

mkdir -p "$QUANT_DIR"

# 2) Quantify all samples
#    Looks for *_R1.clean.fastq.gz / *_R2.clean.fastq.gz pairs
for fq1 in "$READS_DIR"/*_R1.clean.fastq.gz; do
  sample=$(basename "$fq1" _R1.clean.fastq.gz)
  fq2="$READS_DIR/${sample}_R2.clean.fastq.gz"
  outdir="$QUANT_DIR/$sample"

  if [[ ! -f "$fq2" ]]; then
    echo "Paired file missing for $sample, skipping."
    continue
  fi

  echo
  echo "Quantifying sample: $sample ──"
  salmon quant \
    -i "$INDEX_DIR" \
    -l A \
    -1 "$fq1" \
    -2 "$fq2" \
    -p 8 \
    --validateMappings \
    -o "$outdir"
  echo "Output written to $outdir"
done

echo "All samples quantified."
