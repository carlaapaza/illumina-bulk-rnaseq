#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Script: 0_raw_quality_check.sh
# Purpose: Perform raw read quality control with FastQC
# Pipeline:
#   FASTQ.gz (R1/R2) → FastQC → HTML + ZIP reports
# Notes:
#   - Processes all *_R1_001.fastq.gz / *_R2_001.fastq.gz pairs in FASTQ_DIR
#   - Optional aggregation with MultiQC
# Author: Carla Apaza
# ============================================================

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate fastqc

# ── Parameters ──────────────────────────────────────────────
FASTQ_DIR="data/fastq"
FASTQC_OUT="results/0_quality_check/raw"
THREADS="6"

mkdir -p "$FASTQC_OUT"

# ── Run FastQC on all samples ───────────────────────────────
cd "$FASTQ_DIR"
for fq1 in *_R1_001.fastq.gz; do
  sample="${fq1%_R1_001.fastq.gz}"
  fq2="${sample}_R2_001.fastq.gz"
  [[ -f "$fq2" ]] || { echo "[WARN] Missing pair for $fq1, skipping."; continue; }

  echo "── FastQC (raw): $sample"
  fastqc -t "$THREADS" -o "../$FASTQC_OUT" "$fq1" "$fq2"
done

# ── Optional MultiQC summary ────────────────────────────────
conda activate multiqc
multiqc "$FASTQC_OUT" -o "$FASTQC_OUT"

echo "Done: raw FastQC reports in $FASTQC_OUT"
