process AGGREGATE_METRICS {
    tag "aggregate-metrics"
    publishDir "${params.outdir}/perf", mode: 'copy'
    publishDir "${params.outdir}/parity", mode: 'copy', pattern: "modern_mem_parity.tsv"

    input:
    path modern_raw
    path ancient_raw
    path modern_parity

    output:
    path "raw_metrics.tsv", emit: raw
    path "summary_metrics.tsv", emit: summary
    path "speedup_metrics.tsv", emit: speedup
    path "ancient_speedup_metrics.tsv", emit: ancient_speedup
    path "modern_mem_parity.tsv", emit: parity

    script:
    """
    set -euo pipefail
    cat "${modern_raw}" > raw_metrics.tsv
    awk 'NR>1' "${ancient_raw}" >> raw_metrics.tsv
    cp "${modern_parity}" parity_input.tsv
    cat parity_input.tsv > modern_mem_parity.tsv

    awk 'BEGIN{FS=OFS="\\t"; print "dataset","mode","tool","threads","n","elapsed_mean_s","elapsed_sd_s","elapsed_min_s","elapsed_max_s","rss_mean_kb","rss_sd_kb","reads","bases"} NR>1{key=\$1 FS \$2 FS \$3 FS \$4; n[key]++; s[key]+=\$6; s2[key]+=(\$6*\$6); rs[key]+=\$7; rs2[key]+=(\$7*\$7); if(!(key in mi)||\$6<mi[key])mi[key]=\$6; if(!(key in ma)||\$6>ma[key])ma[key]=\$6; reads[key]=\$8; bases[key]=\$9;} END{for(k in n){m=s[k]/n[k]; v=(s2[k]/n[k])-(m*m); if(v<0)v=0; rm=rs[k]/n[k]; rv=(rs2[k]/n[k])-(rm*rm); if(rv<0)rv=0; split(k,p,FS); print p[1],p[2],p[3],p[4],n[k],m,sqrt(v),mi[k],ma[k],rm,sqrt(rv),reads[k],bases[k];}}' raw_metrics.tsv > summary_metrics.tsv
    awk 'BEGIN{FS=OFS="\\t"; print "dataset","mode","tool","threads","elapsed_mean_s","speedup_vs_thread1"} NR>1{k=\$1 FS \$2 FS \$3; t=\$4; e=\$6; means[k FS t]=e; if(t==1) base[k]=e} END{for(mt in means){split(mt,a,FS); key=a[1] FS a[2] FS a[3]; b=base[key]; sp=(b>0)?b/means[mt]:0; print a[1],a[2],a[3],a[4],means[mt],sp}}' summary_metrics.tsv > speedup_metrics.tsv
    awk 'BEGIN{FS=OFS="\\t"} NR==1 || \$1=="ancient"' speedup_metrics.tsv > ancient_speedup_metrics.tsv
    """
}
