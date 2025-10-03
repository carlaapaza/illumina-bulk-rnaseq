#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Script: 1_trimming_reads.sh
# Purpose: Adapter/quality trimming of paired-end reads with BBDuk
# Pipeline:
#   FASTQ.gz (R1/R2) 
#     → BBDuk (adapter + PhiX filtering, quality trimming, length filtering)
#     → Clean FASTQ.gz + per-sample stats
# Notes:
#   - Parameters tuned for RNA-seq (ktrim=r, k=23, mink=11, trimq=12, minlen=30)
#   - Paired-end aware (tbo+tpe)
#   - Optional post-trim FastQC with POSTQC flag
# Author: Carla Apaza
# ============================================================

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate bbmap

# ── Parameters ──────────────────────────────────────────────
FASTQ_DIR="data/fastq"
OUT_DIR="results/1_trimming"
STATS_DIR="$OUT_DIR/stats"
ADAPTERS="resources/adapters.fa"
THREADS="${THREADS:-$(nproc)}"
POSTQC="true"  # set to "true" to run FastQC on trimmed reads
FASTQC_OUT_TRIM="results/0_quality_check/trimmed"

mkdir -p "$OUT_DIR" "$STATS_DIR"
[[ "$POSTQC" == "true" ]] && mkdir -p "$FASTQC_OUT_TRIM"

# ── BBDuk parameters (RNA-seq defaults) ─────────────────────
KTRIM="r"   # trim adapters from right
K=23        # k-mer size
MINK=11     # min k-mer
HDIST=1     # hamming distance
QTRIM="rl"  # quality trim both ends
TRIMQ=10    # quality cutoff
MINLEN=30   # drop short reads
MAXNS=1     # max ambiguous bases allowed
TRIMPOLYG=10

# ── Run BBDuk per sample ────────────────────────────────────
cd "$FASTQ_DIR"
for fq1 in *_R1_001.fastq.gz; do
  sample="${fq1%_R1_001.fastq.gz}"
  fq2="${sample}_R2_001.fastq.gz"
  [[ -f "$fq2" ]] || { echo "[WARN] Missing pair for $fq1, skipping."; continue; }

  out1="$OUT_DIR/${sample}_R1.clean.fastq.gz"
  out2="$OUT_DIR/${sample}_R2.clean.fastq.gz"
  stats="$STATS_DIR/${sample}.bbduk.stats.txt"

  echo "── BBDuk trimming: $sample"
  bbduk.sh \
    in="$fq1" in2="$fq2" \
    out="$out1" out2="$out2" \
    ref="$ADAPTERS,phix" \
    ktrim="$KTRIM" k="$K" mink="$MINK" hdist="$HDIST" \
    tbo tpe \
    qtrim="$QTRIM" trimq="$TRIMQ" trimpolyg="$TRIMPOLYG" \
    minlen="$MINLEN" maxns="$MAXNS" \
    stats="$stats" \
    overwrite=t \
    threads="$THREADS" 

  if [[ "$POSTQC" == "true" ]]; then
    conda activate fastqc
    fastqc -t "$THREADS" -o "$FASTQC_OUT_TRIM" "$out1" "$out2"
    conda activate bbmap
  fi
done

echo "Done: trimmed FASTQs in $OUT_DIR"
[[ "$POSTQC" == "true" ]] && echo "Post-trim FastQC in $FASTQC_OUT_TRIM"
