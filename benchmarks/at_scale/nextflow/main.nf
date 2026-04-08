#!/usr/bin/env nextflow

process RUN_PUBLICATION_BENCH {
    tag "publication-bench"
    publishDir "${params.outdir}/perf", mode: 'copy'
    publishDir "${params.outdir}/parity", mode: 'copy'

    input:
        path ref_modern, stageAs: "ref_modern.fa"
        path ref_ancient, stageAs: "ref_ancient.fa"

    output:
        path "raw_metrics.tsv"
        path "summary_metrics.tsv"
        path "speedup_metrics.tsv"
        path "modern_mem_parity.tsv"

    script:
        """
        set -euo pipefail

        command -v art_illumina >/dev/null 2>&1 || { echo "Missing art_illumina in Pixi env"; exit 1; }
        [ -x "${projectDir}/../.simulators/pygargammel" ] || { echo "Missing ${projectDir}/../.simulators/pygargammel (run pixi task prepare-simulators)"; exit 1; }

        REF_LEN_MOD=\$(awk '!/^>/{n+=length(\$0)} END{print n+0}' "${ref_modern}")
        FOLD_MOD=\$(awk -v n=${params.modern_reads_n} -v rl="\$REF_LEN_MOD" 'BEGIN{if(rl>0) printf "%.8f", (n*2*150)/rl; else print "1.0"}')
        art_illumina -ss HS25 -i "${ref_modern}" -p -l 150 -f "\$FOLD_MOD" -m 220 -s 20 -rs ${params.modern_seed} -o modern_ >/dev/null 2>&1
        mv modern_1.fq modern_r1.fq
        mv modern_2.fq modern_r2.fq

        python - <<'PY'
import random

def load_ref(path):
    seq=[]
    with open(path) as f:
        for line in f:
            if not line.startswith(">"):
                seq.append(line.strip().upper())
    s="".join(seq)
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

merged=[]; r1=[]; r2=[]
for i in range(n):
    s = rng.randrange(0, len(ref)-260)
    merged.append((f"ancm_{i}", ref[s:s+90]))
    r1.append((f"ancp_{i}/1", ref[s:s+75]))
    r2.append((f"ancp_{i}/2", ref[s+120:s+195]))

write_fasta("ancient_merged.fa", merged)
write_fasta("ancient_r1.fa", r1)
write_fasta("ancient_r2.fa", r2)
PY

        python "${projectDir}/../.simulators/pygargammel" --fasta ancient_merged.fa --nick-freq ${params.adna_nick_freq} --overhang-parameter ${params.adna_overhang_parameter} --double-strand-deamination ${params.adna_ds_deamination} --single-strand-deamination ${params.adna_ss_deamination} --output ancient_merged_damaged.fa --log ancient_merged.log
        python "${projectDir}/../.simulators/pygargammel" --fasta ancient_r1.fa --nick-freq ${params.adna_nick_freq} --overhang-parameter ${params.adna_overhang_parameter} --double-strand-deamination ${params.adna_ds_deamination} --single-strand-deamination ${params.adna_ss_deamination} --output ancient_r1_damaged.fa --log ancient_r1.log
        python "${projectDir}/../.simulators/pygargammel" --fasta ancient_r2.fa --nick-freq ${params.adna_nick_freq} --overhang-parameter ${params.adna_overhang_parameter} --double-strand-deamination ${params.adna_ds_deamination} --single-strand-deamination ${params.adna_ss_deamination} --output ancient_r2_damaged.fa --log ancient_r2.log

        python - <<'PY'
def fa_to_fq(fa, fq):
    name=None; seq=[]
    with open(fa) as fi, open(fq, "w") as fo:
        for line in fi:
            line=line.strip()
            if not line: continue
            if line.startswith(">"):
                if name is not None:
                    s="".join(seq)
                    fo.write(f"@{name}\\n{s}\\n+\\n{'I'*len(s)}\\n")
                name=line[1:]; seq=[]
            else:
                seq.append(line)
        if name is not None:
            s="".join(seq)
            fo.write(f"@{name}\\n{s}\\n+\\n{'I'*len(s)}\\n")

fa_to_fq("ancient_merged_damaged.fa", "ancient_merged.fq")
fa_to_fq("ancient_r1_damaged.fa", "ancient_r1.fq")
fa_to_fq("ancient_r2_damaged.fa", "ancient_r2.fq")
PY

        if [ "${params.use_zenodo_adna}" = "true" ]; then
          python - <<'PY'
import json, os, sys, urllib.request
record = "${params.zenodo_record}".strip()
base = f"https://zenodo.org/api/records/{record}"
want = {
  "merged": "${params.zenodo_merged_name}",
  "r1": "${params.zenodo_r1_name}",
  "r2": "${params.zenodo_r2_name}",
}
with urllib.request.urlopen(base) as r:
    meta = json.load(r)
files = meta.get("files", [])
by_name = {f.get("key", ""): f for f in files}
targets = [("merged","ancient_merged.fq"),("r1","ancient_r1.fq"),("r2","ancient_r2.fq")]
for k, out in targets:
    key = want[k].strip()
    if not key:
        continue
    f = by_name.get(key)
    if not f:
        sys.exit(f"Zenodo file not found in record {record}: {key}")
    url = f.get("links", {}).get("self")
    if not url:
        sys.exit(f"Missing download URL for: {key}")
    urllib.request.urlretrieve(url, out)
PY
        fi

        if [ -n "${params.ancient_merged_fq}" ] && [ -f "${params.ancient_merged_fq}" ]; then
          cp "${params.ancient_merged_fq}" ancient_merged.fq
        fi
        if [ -n "${params.ancient_r1_fq}" ] && [ -f "${params.ancient_r1_fq}" ]; then
          cp "${params.ancient_r1_fq}" ancient_r1.fq
        fi
        if [ -n "${params.ancient_r2_fq}" ] && [ -f "${params.ancient_r2_fq}" ]; then
          cp "${params.ancient_r2_fq}" ancient_r2.fq
        fi

        count_reads() { awk 'NR%4==2{r++; b+=length(\$0)} END{printf "%d\\t%d\\n", r, b}' "\$1"; }
        read MREADS MBASES < <(count_reads modern_r1.fq | tr '\\t' ' ')
        read AREADS_M ABASES_M < <(count_reads ancient_merged.fq | tr '\\t' ' ')
        read AREADS_P ABASES_P < <(count_reads ancient_r1.fq | tr '\\t' ' ')

        echo -e "dataset\\tmode\\ttool\\tthreads\\trep\\telapsed_s\\tmax_rss_kb\\treads\\tbases\\tcommand" > raw_metrics.tsv
        parse_real() { awk '/^real /{print \$2}' "\$1"; }
        parse_rss() { awk '/maximum resident set size/{print \$1}' "\$1" | tail -n1; }
        run_time() {
          local out_time="\$1"; shift
          /usr/bin/time -l -p "\$@" >/dev/null 2>"\$out_time" || true
          [ -s "\$out_time" ] || echo "real 0" > "\$out_time"
        }

        "${params.bwa_neo}" index "${ref_modern}"
        "${params.bwa_baseline}" index "${ref_modern}"
        "${params.bwa_mem2}" index "${ref_modern}"

        for rep in \$(seq 1 ${params.performance_repeats}); do
          t=${params.modern_threads}
          run_time neo.time "${params.bwa_neo}" mem -t "\$t" "${ref_modern}" modern_r1.fq modern_r2.fq > neo.sam
          e=\$(parse_real neo.time); r=\$(parse_rss neo.time); [ -n "\$r" ] || r=-1; echo -e "modern\\tmem\\tneo\\t\$t\\t\$rep\\t\$e\\t\$r\\t\$MREADS\\t\$MBASES\\tbwa mem pe" >> raw_metrics.tsv
          [ "\$rep" -eq 1 ] && cp neo.sam neo_modern.sam

          run_time base.time "${params.bwa_baseline}" mem -t "\$t" "${ref_modern}" modern_r1.fq modern_r2.fq > base.sam
          e=\$(parse_real base.time); r=\$(parse_rss base.time); [ -n "\$r" ] || r=-1; echo -e "modern\\tmem\\tbaseline\\t\$t\\t\$rep\\t\$e\\t\$r\\t\$MREADS\\t\$MBASES\\tbwa mem pe" >> raw_metrics.tsv
          [ "\$rep" -eq 1 ] && cp base.sam baseline_modern.sam

          run_time mem2.time "${params.bwa_mem2}" mem -t "\$t" "${ref_modern}" modern_r1.fq modern_r2.fq > mem2.sam
          e=\$(parse_real mem2.time); r=\$(parse_rss mem2.time); [ -n "\$r" ] || r=-1; echo -e "modern\\tmem\\tmem2\\t\$t\\t\$rep\\t\$e\\t\$r\\t\$MREADS\\t\$MBASES\\tbwa-mem2 mem pe" >> raw_metrics.tsv
          [ "\$rep" -eq 1 ] && cp mem2.sam mem2_modern.sam
        done

        "${params.bwa_neo}" index "${ref_ancient}"
        "${params.bwa_baseline}" index "${ref_ancient}"
        for rep in \$(seq 1 ${params.performance_repeats}); do
          for t in ${params.thread_grid}; do
            run_time neo_se.time bash -lc "'${params.bwa_neo}' aln -t \$t '${ref_ancient}' ancient_merged.fq > n.sai && '${params.bwa_neo}' samse '${ref_ancient}' n.sai ancient_merged.fq > /dev/null"
            e=\$(parse_real neo_se.time); r=\$(parse_rss neo_se.time); [ -n "\$r" ] || r=-1; echo -e "ancient\\taln_samse\\tneo\\t\$t\\t\$rep\\t\$e\\t\$r\\t\$AREADS_M\\t\$ABASES_M\\tbwa aln+samse" >> raw_metrics.tsv

            run_time base_se.time bash -lc "'${params.bwa_baseline}' aln -t \$t '${ref_ancient}' ancient_merged.fq > b.sai && '${params.bwa_baseline}' samse '${ref_ancient}' b.sai ancient_merged.fq > /dev/null"
            e=\$(parse_real base_se.time); r=\$(parse_rss base_se.time); [ -n "\$r" ] || r=-1; echo -e "ancient\\taln_samse\\tbaseline\\t\$t\\t\$rep\\t\$e\\t\$r\\t\$AREADS_M\\t\$ABASES_M\\tbwa aln+samse" >> raw_metrics.tsv

            run_time neo_pe.time bash -lc "'${params.bwa_neo}' aln -t \$t '${ref_ancient}' ancient_r1.fq > n1.sai && '${params.bwa_neo}' aln -t \$t '${ref_ancient}' ancient_r2.fq > n2.sai && '${params.bwa_neo}' sampe '${ref_ancient}' n1.sai n2.sai ancient_r1.fq ancient_r2.fq > /dev/null"
            e=\$(parse_real neo_pe.time); r=\$(parse_rss neo_pe.time); [ -n "\$r" ] || r=-1; echo -e "ancient\\taln_sampe\\tneo\\t\$t\\t\$rep\\t\$e\\t\$r\\t\$AREADS_P\\t\$ABASES_P\\tbwa aln+sampe" >> raw_metrics.tsv

            run_time base_pe.time bash -lc "'${params.bwa_baseline}' aln -t \$t '${ref_ancient}' ancient_r1.fq > b1.sai && '${params.bwa_baseline}' aln -t \$t '${ref_ancient}' ancient_r2.fq > b2.sai && '${params.bwa_baseline}' sampe '${ref_ancient}' b1.sai b2.sai ancient_r1.fq ancient_r2.fq > /dev/null"
            e=\$(parse_real base_pe.time); r=\$(parse_rss base_pe.time); [ -n "\$r" ] || r=-1; echo -e "ancient\\taln_sampe\\tbaseline\\t\$t\\t\$rep\\t\$e\\t\$r\\t\$AREADS_P\\t\$ABASES_P\\tbwa aln+sampe" >> raw_metrics.tsv
          done
        done

        awk 'BEGIN{FS=OFS="\\t"; print "dataset","mode","tool","threads","n","elapsed_mean_s","elapsed_sd_s","elapsed_min_s","elapsed_max_s","rss_mean_kb","rss_sd_kb","reads","bases"} NR>1{key=\$1 FS \$2 FS \$3 FS \$4; n[key]++; s[key]+=\$6; s2[key]+=(\$6*\$6); rs[key]+=\$7; rs2[key]+=(\$7*\$7); if(!(key in mi)||\$6<mi[key])mi[key]=\$6; if(!(key in ma)||\$6>ma[key])ma[key]=\$6; reads[key]=\$8; bases[key]=\$9;} END{for(k in n){m=s[k]/n[k]; v=(s2[k]/n[k])-(m*m); if(v<0)v=0; rm=rs[k]/n[k]; rv=(rs2[k]/n[k])-(rm*rm); if(rv<0)rv=0; split(k,p,FS); print p[1],p[2],p[3],p[4],n[k],m,sqrt(v),mi[k],ma[k],rm,sqrt(rv),reads[k],bases[k];}}' raw_metrics.tsv > summary_metrics.tsv
        awk 'BEGIN{FS=OFS="\\t"; print "dataset","mode","tool","threads","elapsed_mean_s","speedup_vs_thread1"} NR>1{k=\$1 FS \$2 FS \$3; t=\$4; e=\$6; means[k FS t]=e; if(t==1) base[k]=e} END{for(mt in means){split(mt,a,FS); key=a[1] FS a[2] FS a[3]; b=base[key]; sp=(b>0)?b/means[mt]:0; print a[1],a[2],a[3],a[4],means[mt],sp}}' summary_metrics.tsv > speedup_metrics.tsv

        norm() { awk 'BEGIN{FS=OFS="\\t"} !/^@/{print \$1,\$2,\$3,\$4,\$5,\$6,\$10,\$11}' "\$1" | sort; }
        norm neo_modern.sam > neo.norm
        norm baseline_modern.sam > baseline.norm
        norm mem2_modern.sam > mem2.norm
        d1=\$(diff -u neo.norm baseline.norm | awk 'END{print NR}')
        d2=\$(diff -u neo.norm mem2.norm | awk 'END{print NR}')
        echo -e "comparison\\tdiff_lines" > modern_mem_parity.tsv
        echo -e "neo_vs_baseline\\t${d1:-0}" >> modern_mem_parity.tsv
        echo -e "neo_vs_mem2\\t${d2:-0}" >> modern_mem_parity.tsv
        """
}

workflow {
    def refModern = file(params.ref_fa, checkIfExists: true)
    def refAncient = file(params.ref_pe_fa, checkIfExists: true)
    RUN_PUBLICATION_BENCH(refModern, refAncient)
}
