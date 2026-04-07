# mem2 (planned unified `bwa mem`)

This directory is reserved for **in-tree integration** of [bwa-mem2](https://github.com/bwa-mem2/bwa-mem2) sources so that a single `bwa` binary can dispatch `mem` to the mem2 implementation.

**Current state:** mem2 is built from `third_party/bwa-mem2` (see `scripts/fetch-bwa-mem2.sh` and root `CMakeLists.txt` option `BWA_NEO_BUILD_BWA_MEM2`).

**Next steps:** vendor C++ sources here, unify FASTQ/SAM helpers with the rest of the tree, add SAM regression tests vs the standalone `bwa-mem2` binary, then remove duplicate `bwamem.c` paths.
