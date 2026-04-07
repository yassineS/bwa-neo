# Minimal smoke target for CI (extend with Zenodo download + Snakemake).
.PHONY: smoke
smoke:
	@echo "refbias smoke: ensure bwa exists in PATH or set BWA=..."
	@root_dir=$$(cd "$$(dirname "$(lastword $(MAKEFILE_LIST))")/../.." && pwd); \
	test -n "$$BWA" || BWA="$$root_dir/bwa"; \
	if ! test -x "$$BWA"; then echo "Build bwa first: make -C $$root_dir"; exit 1; fi; \
	echo "Using $$BWA"; \
	$$BWA 2>&1 | head -1
