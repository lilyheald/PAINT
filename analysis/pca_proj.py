import subprocess
import os

# ======================
# BASE PATHS
# ======================

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DATA_DIR = os.path.join(BASE_DIR, "data")

# ======================
# FILE PATHS
# ======================

modern_vcf = os.path.join(DATA_DIR, "sgdp.wg.vcf.gz")
ancient_vcf = os.path.join(DATA_DIR, "ancient_sgdp_wg.vcf.gz")

freq_prefix = os.path.join(DATA_DIR, "sgdp.wg.fixed")
prune_prefix = os.path.join(DATA_DIR, "sgdp.wg.pruned")
pca_prefix = os.path.join(DATA_DIR, "sgdp.wg.pca")
ancient_prefix = os.path.join(DATA_DIR, "ancient")
projection_prefix = os.path.join(DATA_DIR, "ancient.projected")

threads = max(1, os.cpu_count() - 2)

plink = "plink2"


# ======================
# HELPER FUNCTION
# ======================

def run_cmd(cmd):
    print(f"\nRunning:\n{cmd}\n")
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)

    print(result.stdout)
    print(result.stderr)

    if result.returncode != 0:
        raise RuntimeError("Command failed")

    print("Done.\n")


# ======================
# STEP 1: FIX IDS + BIALLELIC + FREQUENCIES
# ======================

freq_cmd = f"""
{plink} \
--vcf "{modern_vcf}" \
--set-all-var-ids @:# \
--max-alleles 2 \
--freq \
--threads {threads} \
--out "{freq_prefix}"
"""

run_cmd(freq_cmd)


# ======================
# STEP 2: LIGHT LD PRUNING (ALLOW SMALL N)
# ======================

prune_cmd = f"""
{plink} \
--vcf "{modern_vcf}" \
--set-all-var-ids @:# \
--max-alleles 2 \
--maf 0.05 \
--indep-pairwise 200 50 0.7 \
--bad-ld \
--threads {threads} \
--out "{prune_prefix}"
"""

run_cmd(prune_cmd)


# ======================
# STEP 3: PCA (EXACT, 10 PCs)
# ======================

pca_cmd = f"""
{plink} \
--vcf "{modern_vcf}" \
--set-all-var-ids @:# \
--max-alleles 2 \
--extract "{prune_prefix}.prune.in" \
--read-freq "{freq_prefix}.afreq" \
--pca 10 allele-wts \
--threads {threads} \
--out "{pca_prefix}"
"""

run_cmd(pca_cmd)


# ======================
# STEP 4: PREP ANCIENT (MATCH SNP SET)
# ======================

ancient_cmd = f"""
{plink} \
--vcf "{ancient_vcf}" \
--set-all-var-ids @:# \
--max-alleles 2 \
--extract "{prune_prefix}.prune.in" \
--make-bed \
--threads {threads} \
--out "{ancient_prefix}"
"""

run_cmd(ancient_cmd)


# ======================
# STEP 5: PROJECT ANCIENT
# ======================

projection_cmd = f"""
{plink} \
--bfile "{ancient_prefix}" \
--score "{pca_prefix}.eigenvec.allele" 2 5 header-read \
--score-col-nums 6-15 \
--threads {threads} \
--out "{projection_prefix}"
"""

run_cmd(projection_cmd)


print("🎉 ALL DONE!")
print(f"Projected PCs: {projection_prefix}.sscore")