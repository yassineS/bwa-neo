# Tests

| Test | Command | Role |
|------|---------|------|
| **smoke_align** | `tests/smoke_align.sh ./bwa` | Index + `aln` + `samse` (and `samse -t` header check). |
| **golden_sam** | `tests/golden_sam.sh ./bwa` | Mapped read: first 11 SAM fields match `fixtures/tiny/expected.r1.first11.tsv`; `samse -t` matches single-threaded. |
| **unit** | CTest `unit` | GoogleTest scaffold (`test_unit.cpp`). |

Fixtures live under **`fixtures/tiny/`**. To change the golden expectation, edit `expected.r1.first11.tsv` and run `golden_sam.sh` locally before committing.
