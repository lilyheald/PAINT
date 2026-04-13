import subprocess
import os

# base paths

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DATA_DIR = os.path.join(BASE_DIR, "data")

# file paths

modern_vcf = os.path.join(DATA_DIR, "sgdp.wg.vcf.gz")
ancient_vcf = os.path.join(DATA_DIR, "ancient_sgdp_wg.vcf.gz")

modern_prefix = os.path.join(DATA_DIR, "sgdp.wg.cleaned")
freq_prefix = os.path.join(DATA_DIR, "sgdp.wg.fixed")
prune_prefix = os.path.join(DATA_DIR, "sgdp.wg.pruned")
pca_prefix = os.path.join(DATA_DIR, "sgdp.wg.pca")
ancient_prefix = os.path.join(DATA_DIR, "ancient")
projection_prefix = os.path.join(DATA_DIR, "ancient.projected")

threads = 6
plink = "plink2"

# helper

def run_cmd(cmd):
    print(f"\nRunning:\n{cmd}\n")
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)

    print(result.stdout)
    print(result.stderr)

    if result.returncode != 0:
        raise RuntimeError("Command failed")

    print("Done.\n")


# clean modern

clean_cmd = f"""
{plink} \
--vcf "{modern_vcf}" \
--set-all-var-ids @:# \
--rm-dup force-first \
--max-alleles 2 \
--make-pgen \
--threads {threads} \
--out "{modern_prefix}"
"""
run_cmd(clean_cmd)


# compute freqs

freq_cmd = f"""
{plink} \
--pfile "{modern_prefix}" \
--freq \
--threads {threads} \
--out "{freq_prefix}"
"""
run_cmd(freq_cmd)


# LD pruning

prune_cmd = f"""
{plink} \
--pfile "{modern_prefix}" \
--maf 0.05 \
--indep-pairwise 200 50 0.7 \
--bad-ld \
--threads {threads} \
--out "{prune_prefix}"
"""
run_cmd(prune_cmd)


# PCA

pca_cmd = f"""
{plink} \
--pfile "{modern_prefix}" \
--extract "{prune_prefix}.prune.in" \
--read-freq "{freq_prefix}.afreq" \
--pca 10 allele-wts \
--threads {threads} \
--out "{pca_prefix}"
"""
run_cmd(pca_cmd)


# prepare ancient data for projection

ancient_cmd = f"""
{plink} \
--vcf "{ancient_vcf}" \
--set-all-var-ids @:# \
--rm-dup force-first \
--max-alleles 2 \
--extract "{prune_prefix}.prune.in" \
--make-bed \
--threads {threads} \
--out "{ancient_prefix}"
"""
run_cmd(ancient_cmd)


# project ancient samples onto modern PCA space

projection_cmd = f"""
{plink} \
--bfile "{ancient_prefix}" \
--read-freq "{freq_prefix}.afreq" \
--score "{pca_prefix}.eigenvec.allele" 2 5 header-read ignore-dup-ids \
--score-col-nums 6-15 \
--threads {threads} \
--out "{projection_prefix}"
"""
run_cmd(projection_cmd)

print(f"Projected PCs: {projection_prefix}.sscore")