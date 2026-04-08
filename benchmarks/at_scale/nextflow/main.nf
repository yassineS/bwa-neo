#!/usr/bin/env nextflow
/*
 * bwa-neo benchmark smoke: index + aln + samse on tiny fixtures.
 * Optional: params.bwa_baseline — run same pipeline and diff first 11 SAM fields vs neo.
 */
nextflow.enable.dsl = 2

process BWA_ALN_SAMSE {
    tag "${meta.id}"
    publishDir "${params.outdir}/${meta.id}", mode: 'copy'

    input:
        tuple val(meta), path(ref), path(reads)

    output:
        tuple val(meta), path("${meta.id}.sam"), emit: sam
        path('versions.txt'), emit: versions

    script:
        def bw = meta.bwa_bin as String
        def sid = meta.id as String
        """
        set -euo pipefail
        # Inputs are staged by Nextflow (symlinks); use them in place for index + aln + samse
        '${bw}' index ${ref}
        '${bw}' aln -t ${params.threads_aln} ${ref} ${reads} > reads.sai
        '${bw}' samse -t ${params.threads_samse} ${ref} reads.sai ${reads} > ${sid}.sam
        echo "id=${meta.id}" > versions.txt
        echo "bwa=${bw}" >> versions.txt
        '${bw}' 2>&1 | head -n 3 >> versions.txt || true
        """
}

process SAM_FIRST11_DIFF {
    publishDir "${params.outdir}/parity", mode: 'copy'

    input:
        tuple path(neo_sam), path(base_sam)

    output:
        path('parity.ok'), emit: ok
        path('parity.first11.diff'), optional: true, emit: diff

    script:
        """
        set -euo pipefail
        awk '/^[^@]/{
          for(i=1;i<=11;i++) printf "%s%s", \$i, (i<11 ? "\\t" : "\\n")
          exit
        }' '${neo_sam}' > neo.first11.tsv
        awk '/^[^@]/{
          for(i=1;i<=11;i++) printf "%s%s", \$i, (i<11 ? "\\t" : "\\n")
          exit
        }' '${base_sam}' > base.first11.tsv
        if cmp -s neo.first11.tsv base.first11.tsv; then
          echo "SAM first-11 fields: neo == baseline OK" > parity.ok
        else
          echo "SAM first-11 fields: MISMATCH" > parity.ok
          diff -u base.first11.tsv neo.first11.tsv > parity.first11.diff || true
          exit 1
        fi
        """
}

workflow {
    def ref = file(params.ref_fa, checkIfExists: true)
    def reads = file(params.reads_fq, checkIfExists: true)

    def neo_meta = [id: 'neo', bwa_bin: params.bwa_neo]
    def ch = channel.of(tuple(neo_meta, ref, reads))

    if (params.bwa_baseline) {
        def base_meta = [id: 'baseline', bwa_bin: params.bwa_baseline]
        ch = ch.mix(channel.of(tuple(base_meta, ref, reads)))
    }

    BWA_ALN_SAMSE(ch)

    if (params.bwa_baseline) {
        def neo_sam = BWA_ALN_SAMSE.out.sam.filter { meta, sam -> meta.id == 'neo' }.map { m, s -> s }.first()
        def base_sam = BWA_ALN_SAMSE.out.sam.filter { meta, sam -> meta.id == 'baseline' }.map { m, s -> s }.first()
        SAM_FIRST11_DIFF(neo_sam.combine(base_sam))
    }
}
