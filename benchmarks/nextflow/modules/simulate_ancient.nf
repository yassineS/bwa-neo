process SIMULATE_ANCIENT_PYGARGAMMEL {
    tag "simulate-ancient-pygargammel"

    input:
    path ref_ancient

    output:
    path "ancient_r1.fq", emit: r1
    path "ancient_r2.fq", emit: r2

    script:
    """
    set -euo pipefail
    [ -x "${projectDir}/../.simulators/pygargammel" ] || { echo "Missing ${projectDir}/../.simulators/pygargammel (run pixi task prepare-simulators)"; exit 1; }

    python - <<'PY'
import random

def load_ref(path):
    seq = []
    with open(path) as f:
        for line in f:
            if not line.startswith(">"):
                seq.append(line.strip().upper())
    s = "".join(seq)
    if len(s) < 500:
        s = s * ((500 // len(s)) + 2)
    return s

def write_fasta(path, records):
    with open(path, "w") as out:
        for name, seq in records:
            out.write(f">{name}\\n{seq}\\n")

ref = load_ref("${ref_ancient}")
n = int("${params.ancient_reads_n}")
rng = random.Random(int("${params.ancient_seed}"))
r1 = []
r2 = []
for i in range(n):
    s = rng.randrange(0, len(ref) - 260)
    r1.append((f"ancp_{i}/1", ref[s:s+75]))
    r2.append((f"ancp_{i}/2", ref[s+120:s+195]))
write_fasta("ancient_r1.fa", r1)
write_fasta("ancient_r2.fa", r2)
PY

    python "${projectDir}/../.simulators/pygargammel" \
      --fasta ancient_r1.fa \
      --seed "${params.ancient_seed}" \
      --nick-freq ${params.adna_nick_freq} \
      --overhang-parameter ${params.adna_overhang_parameter} \
      --double-strand-deamination ${params.adna_ds_deamination} \
      --single-strand-deamination ${params.adna_ss_deamination} \
      --output ancient_r1_damaged.fa \
      --log ancient_r1.log

    python "${projectDir}/../.simulators/pygargammel" \
      --fasta ancient_r2.fa \
      --seed \$(( ${params.ancient_seed} + 1 )) \
      --nick-freq ${params.adna_nick_freq} \
      --overhang-parameter ${params.adna_overhang_parameter} \
      --double-strand-deamination ${params.adna_ds_deamination} \
      --single-strand-deamination ${params.adna_ss_deamination} \
      --output ancient_r2_damaged.fa \
      --log ancient_r2.log

    python - <<'PY'
def fa_to_fq(fa, fq):
    name = None
    seq = []
    with open(fa) as fi, open(fq, "w") as fo:
        for line in fi:
            line = line.strip()
            if not line:
                continue
            if line.startswith(">"):
                if name is not None:
                    s = "".join(seq)
                    fo.write(f"@{name}\\n{s}\\n+\\n{'I'*len(s)}\\n")
                name = line[1:]
                seq = []
            else:
                seq.append(line)
        if name is not None:
            s = "".join(seq)
            fo.write(f"@{name}\\n{s}\\n+\\n{'I'*len(s)}\\n")

fa_to_fq("ancient_r1_damaged.fa", "ancient_r1.fq")
fa_to_fq("ancient_r2_damaged.fa", "ancient_r2.fq")
PY

    if [ -n "${params.ancient_r1_fq}" ] && [ -f "${params.ancient_r1_fq}" ]; then
      cp "${params.ancient_r1_fq}" ancient_r1.fq
    fi
    if [ -n "${params.ancient_r2_fq}" ] && [ -f "${params.ancient_r2_fq}" ]; then
      cp "${params.ancient_r2_fq}" ancient_r2.fq
    fi
    """
}
