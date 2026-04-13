import subprocess
import os

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DATA_DIR = os.path.join(BASE_DIR, "data")

modern_vcf = os.path.join(DATA_DIR, "pigmentation_snps.vcf.gz")
ancient_vcf = os.path.join(DATA_DIR, "ancient_pigmentation.vcf.gz")

freq_prefix = os.path.join(DATA_DIR, "pigmentation_freq")
pca_prefix = os.path.join(DATA_DIR, "pigmentation_pca")
ancient_prefix = os.path.join(DATA_DIR, "ancient")
projection_prefix = os.path.join(DATA_DIR, "ancient_projected")

threads = 6
plink = "plink2"


def run_cmd(cmd):
    print(f"\nRunning:\n{cmd}\n")
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)

    print(result.stdout)
    print(result.stderr)

    if result.returncode != 0:
        raise RuntimeError("Command failed")

    print("Done.\n")


# ======================
# STEP 1: FREQUENCIES (MODERN)
# ======================

run_cmd(f"""
{plink} \
--vcf "{modern_vcf}" \
--set-all-var-ids @:#:$r:$a \
--max-alleles 2 \
--freq \
--out "{freq_prefix}"
""")


# ======================
# STEP 2: PCA WITH ALLELE WEIGHTS
# ======================

run_cmd(f"""
{plink} \
--vcf "{modern_vcf}" \
--set-all-var-ids @:#:$r:$a \
--max-alleles 2 \
--read-freq "{freq_prefix}.afreq" \
--pca 10 allele-wts \
--out "{pca_prefix}"
""")


# ======================
# STEP 3: PREP ANCIENT
# ======================

run_cmd(f"""
{plink} \
--vcf "{ancient_vcf}" \
--set-all-var-ids @:#:$r:$a \
--max-alleles 2 \
--make-bed \
--out "{ancient_prefix}"
""")


# ======================
# STEP 4: PROJECT
# ======================

run_cmd(f"""
{plink} \
--bfile "{ancient_prefix}" \
--read-freq "{freq_prefix}.afreq" \
--score "{pca_prefix}.eigenvec.allele" 2 5 header-read \
--score-col-nums 6-15 \
--out "{projection_prefix}"
""")


print("🎉 DONE!")
print(f"Projected PCs: {projection_prefix}.sscore")