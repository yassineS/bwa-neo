Welcome to the **bwa-neo** wiki. This is a **Burrows–Wheeler aligner (BWA)** fork used to experiment with clearer code layout, faster parallel paths for short-read backtracking (`aln`, `samse`, `sampe`), and a staged story around **bwa-mem2** and `mem`.

## Relationship to upstream

- **Upstream BWA** ([lh3/bwa](https://github.com/lh3/bwa)) remains the reference for production use of the classic tool.
- **bwa-mem2** ([bwa-mem2/bwa-mem2](https://github.com/bwa-mem2/bwa-mem2)) is the supported path for a faster `mem` implementation outside this fork.
- **This fork** is deliberately **experimental**. Treat it as a development and evaluation tree unless you have a concrete reason to depend on it.

## Where to read more (source of truth on `main`)

- Fork overview and quick start: [docs/BWA-NEO.md](https://github.com/yassineS/bwa-neo/blob/main/docs/BWA-NEO.md)
- Long-form upstream-oriented readme (still shipped in-tree): [README.md](https://github.com/yassineS/bwa-neo/blob/main/README.md)

## Wiki map

| Page | Purpose |
|------|---------|
| [Contributing and agents](Contributing-and-agents) | How humans and coding agents should work in this repository |
| [Build and test](Build-and-test) | Compile and verify the tree |
| [Architecture and scope](Architecture-and-scope) | Pointers to requirements, design, and the task checklist |
| [Benchmarks and research](Benchmarks-and-research) | At-scale validation and refbias context |
| [Security, licence, and conduct](Security-licence-and-conduct) | Reporting, licence, governance |

Canonical copies of long documents stay in the Git repository; this wiki duplicates only the high-traffic contributor and agent material and summarises the rest.
