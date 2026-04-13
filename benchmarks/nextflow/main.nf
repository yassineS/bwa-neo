#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { SIMULATE_MODERN_ISS } from './modules/simulate_modern'
include { SIMULATE_ANCIENT_PYGARGAMMEL } from './modules/simulate_ancient'
include { MERGE_ANCIENT_READS } from './modules/merge_ancient'
include { RUN_MODERN_BENCH } from './modules/bench_modern'
include { RUN_ANCIENT_BENCH } from './modules/bench_ancient'
include { MODERN_PARITY } from './modules/parity_modern'
include { AGGREGATE_METRICS } from './modules/aggregate_metrics'
include { RENDER_PUBLICATION_ASSETS } from './modules/render_publication_assets'

workflow {
    def refModern = file(params.ref_fa, checkIfExists: true)
    def refAncient = file(params.ref_pe_fa, checkIfExists: true)

    SIMULATE_MODERN_ISS(Channel.value(refModern))
    SIMULATE_ANCIENT_PYGARGAMMEL(Channel.value(refAncient))
    MERGE_ANCIENT_READS(SIMULATE_ANCIENT_PYGARGAMMEL.out.r1, SIMULATE_ANCIENT_PYGARGAMMEL.out.r2)

    RUN_MODERN_BENCH(SIMULATE_MODERN_ISS.out.ref, SIMULATE_MODERN_ISS.out.r1, SIMULATE_MODERN_ISS.out.r2)
    RUN_ANCIENT_BENCH(
        Channel.value(refAncient),
        MERGE_ANCIENT_READS.out.merged,
        SIMULATE_ANCIENT_PYGARGAMMEL.out.r1,
        SIMULATE_ANCIENT_PYGARGAMMEL.out.r2
    )

    MODERN_PARITY(
        RUN_MODERN_BENCH.out.neo_sam,
        RUN_MODERN_BENCH.out.baseline_sam,
        RUN_MODERN_BENCH.out.mem2_sam
    )

    AGGREGATE_METRICS(
        RUN_MODERN_BENCH.out.metrics,
        RUN_ANCIENT_BENCH.out.metrics,
        MODERN_PARITY.out.parity
    )

    RENDER_PUBLICATION_ASSETS(
        AGGREGATE_METRICS.out.raw,
        AGGREGATE_METRICS.out.summary,
        AGGREGATE_METRICS.out.speedup,
        AGGREGATE_METRICS.out.ancient_speedup,
        AGGREGATE_METRICS.out.parity
    )
}
