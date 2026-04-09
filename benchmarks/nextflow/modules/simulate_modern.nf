process SIMULATE_MODERN_ISS {
    tag "simulate-modern-iss"

    input:
    path ref_modern

    output:
    path "modern_ref.fa", emit: ref
    path "modern_r1.fq", emit: r1
    path "modern_r2.fq", emit: r2

    script:
    """
    set -euo pipefail
    command -v iss >/dev/null 2>&1 || { echo "Missing InSilicoSeq (iss) in Pixi env"; exit 1; }
    cp "${ref_modern}" modern_ref.fa
    python - <<'PY'
from pathlib import Path

inp = Path("modern_ref.fa")
seqs = []
name = None
buf = []
for line in inp.read_text().splitlines():
    if line.startswith(">"):
        if name is not None:
            seqs.append((name, "".join(buf)))
        name = line[1:].strip() or "ref"
        buf = []
    else:
        buf.append(line.strip().upper())
if name is not None:
    seqs.append((name, "".join(buf)))

with inp.open("w") as out:
    for n, s in seqs:
        if len(s) < 1000 and len(s) > 0:
            s = s * ((1000 // len(s)) + 1)
        out.write(f">{n}\\n{s}\\n")
PY

    iss generate \
      --genomes modern_ref.fa \
      --model "${params.modern_iss_model}" \
      --n_reads "${params.modern_reads_n}" \
      --cpus "${params.modern_threads}" \
      --seed "${params.modern_seed}" \
      --output modern_sim >/dev/null

    mv modern_sim_R1.fastq modern_r1.fq
    mv modern_sim_R2.fastq modern_r2.fq

    # Tiny references can yield empty ISS output; fallback keeps workflow usable.
    if [ ! -s modern_r1.fq ] || [ ! -s modern_r2.fq ]; then
      command -v art_illumina >/dev/null 2>&1 || { echo "Missing art_illumina for fallback"; exit 1; }
      REF_LEN=\$(awk '!/^>/{n+=length(\$0)} END{print n+0}' modern_ref.fa)
      FOLD=\$(awk -v n=${params.modern_reads_n} -v rl="\$REF_LEN" 'BEGIN{if(rl>0) printf "%.8f", (n*2*150)/rl; else print "1.0"}')
      art_illumina -ss HS25 -i modern_ref.fa -p -l 150 -f "\$FOLD" -m 220 -s 20 -rs ${params.modern_seed} -o modern_fallback_ >/dev/null 2>&1
      mv modern_fallback_1.fq modern_r1.fq
      mv modern_fallback_2.fq modern_r2.fq
    fi
    """
}
