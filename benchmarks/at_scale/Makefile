# Nextflow smoke for benchmarks/at_scale (requires `nextflow` on PATH, `bwa` built at repo root).
ROOT := $(abspath ../..)
NF_HOME := $(ROOT)/.nextflow_home
NF_DIR := $(abspath nextflow)

.PHONY: smoke-nf
smoke-nf:
	@test -x "$(ROOT)/bwa" || { echo "Build bwa first: cd $(ROOT) && make -j"; exit 1; }
	@mkdir -p "$(NF_HOME)"
	cd "$(NF_DIR)" && NXF_HOME="$(NF_HOME)" nextflow run main.nf -profile standard --outdir "$(NF_DIR)/results_smoke"
