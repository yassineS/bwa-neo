# third_party

## bwa-mem2

The **`bwa mem`** replacement lives in [bwa-mem2](https://github.com/bwa-mem2/bwa-mem2) (MIT). Populate this directory with:

```bash
./scripts/fetch-bwa-mem2.sh
```

Then either:

- `cd third_party/bwa-mem2 && make` to produce the `bwa-mem2` binary, or
- Configure CMake with `-DBWA_NEO_BUILD_BWA_MEM2=ON` after sources exist (builds via `ExternalProject`).

Long-term bwa-neo aims to unify `mem` into a single binary; see `design.md` and `tasks.md`.
