#!/bin/bash
#SBATCH --job-name=sgdp_subset
#SBATCH --account=tlasisi0
#SBATCH --partition=standard
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=60G
#SBATCH --time=46:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=lheald@umich.edu
#SBATCH --array=1-279%20

set -euo pipefail

module load Bioinformatics bcftools

echo "Job: $SLURM_JOB_ID"
echo "Task: $SLURM_ARRAY_TASK_ID"
echo "Node: $(hostname)"

############################################
# Directories
############################################
SCRATCH_BASE=/scratch/tlasisi_root/tlasisi0/lheald
SCRATCH_DIR=${SCRATCH_BASE}/sgdp_subset/${SLURM_JOB_ID}/${SLURM_ARRAY_TASK_ID}

DOWNLOAD_DIR=${SCRATCH_DIR}/downloads
TMP_DIR=${SCRATCH_DIR}/tmp

FINAL_DIR=/nfs/turbo/lsa-tlasisi1/lheald_thesis/aDNA_data/sgdp/subsets

mkdir -p "$DOWNLOAD_DIR" "$TMP_DIR" "$FINAL_DIR"

# Only clean scratch on success
trap 'status=$?; if [[ $status -eq 0 ]]; then rm -rf "$SCRATCH_DIR"; else echo "Preserving scratch for debugging: $SCRATCH_DIR"; fi' EXIT

cd "$SCRATCH_DIR"

############################################
# Wget commands
############################################
WGET_CMD_FILE=/nfs/turbo/lsa-tlasisi1/lheald_thesis/aDNA_data/wget_commands.txt

LINE1=$(sed -n "$((SLURM_ARRAY_TASK_ID*2-1))p" "$WGET_CMD_FILE")
LINE2=$(sed -n "$((SLURM_ARRAY_TASK_ID*2))p" "$WGET_CMD_FILE")

if [[ -z "$LINE1" || -z "$LINE2" ]]; then
    echo "ERROR: Missing wget command for task $SLURM_ARRAY_TASK_ID"
    exit 1
fi

############################################
# Extract filenames (strip quotes)
############################################
FILE1=$(echo "$LINE1" | awk '{print $4}' | tr -d '"')
FILE2=$(echo "$LINE2" | awk '{print $4}' | tr -d '"')

############################################
# Determine which is VCF vs TBI
############################################
if [[ "$FILE1" == *.vcf.gz ]]; then
    VCF_FILE="$FILE1"
    TBI_FILE="$FILE2"
    VCF_LINE="$LINE1"
    TBI_LINE="$LINE2"
elif [[ "$FILE2" == *.vcf.gz ]]; then
    VCF_FILE="$FILE2"
    TBI_FILE="$FILE1"
    VCF_LINE="$LINE2"
    TBI_LINE="$LINE1"
else
    echo "ERROR: Could not determine VCF file for task $SLURM_ARRAY_TASK_ID"
    exit 1
fi

VCF_PATH="$DOWNLOAD_DIR/$VCF_FILE"
TBI_PATH="$DOWNLOAD_DIR/$TBI_FILE"

BASE=${VCF_FILE%.vcf.gz}

############################################
# Skip if already processed
############################################
if [[ -f "$FINAL_DIR/${BASE}_sgdp.bcf" && -f "$FINAL_DIR/${BASE}_snps.bcf" ]]; then
    echo "Sample $BASE already processed — skipping."
    exit 0
fi

############################################
# Extract URLs safely
############################################
VCF_URL=$(echo "$VCF_LINE" | sed -n 's/.*"\(https[^"]*\)".*/\1/p')
TBI_URL=$(echo "$TBI_LINE" | sed -n 's/.*"\(https[^"]*\)".*/\1/p')

echo "VCF file: $VCF_FILE"
echo "TBI file: $TBI_FILE"
echo "Downloading to: $DOWNLOAD_DIR"

############################################
# Download
############################################
wget -c -O "$VCF_PATH" "$VCF_URL"
wget -c -O "$TBI_PATH" "$TBI_URL"

############################################
# Validate downloads
############################################
if [[ ! -s "$VCF_PATH" || ! -s "$TBI_PATH" ]]; then
    echo "ERROR: Download failed or files are empty"
    exit 1
fi

############################################
# SNP panels
############################################
SGDP_PANEL=/nfs/turbo/lsa-tlasisi1/lheald_thesis/aDNA_data/snps/sgdp.snps.pos
GEN_PANEL=/nfs/turbo/lsa-tlasisi1/lheald_thesis/aDNA_data/snps/snps.bed

############################################
# Subset SGDP SNP panel
############################################
bcftools view \
    --threads 4 \
    -R "$SGDP_PANEL" \
    -O b \
    -o "$FINAL_DIR/${BASE}_sgdp.bcf" \
    "$VCF_PATH"

bcftools index --threads 4 "$FINAL_DIR/${BASE}_sgdp.bcf"

############################################
# Subset general SNP panel
############################################
bcftools view \
    --threads 4 \
    -R "$GEN_PANEL" \
    -O b \
    -o "$FINAL_DIR/${BASE}_snps.bcf" \
    "$VCF_PATH"

bcftools index --threads 4 "$FINAL_DIR/${BASE}_snps.bcf"

############################################
# Done
############################################
echo "Task $SLURM_ARRAY_TASK_ID completed at $(date)"
