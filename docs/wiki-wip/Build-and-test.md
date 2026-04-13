# Build and test

Canonical detail: [docs/DEVELOPMENT.md](https://github.com/yassineS/bwa-neo/blob/main/docs/DEVELOPMENT.md) (Git and `gh`) and [tests/README.md](https://github.com/yassineS/bwa-neo/blob/main/tests/README.md) (fixture layout and scripts).

## Build

From your clone of the repository (recommended path `~/Code/bwa-neo` on a workstation):

```bash
cd ~/Code/bwa-neo
make -j                    # classic Makefile; produces ./bwa
```

CMake alternative:

```bash
cmake -S . -B build && cmake --build build   # produces build/bwa
```

**Dependencies:** a C compiler, **zlib**, and **pthread** (the Makefile adds platform-specific libraries such as `-lrt` on Linux where needed).

### Cursor Cloud / constrained environments

If the default Clang cannot link `libstdc++` for CMake’s C++ test harness, prefer:

```bash
CC=gcc CXX=g++ cmake -S . -B build -DBUILD_TESTING=ON -G Ninja
cmake --build build
```

## Test

**Makefile binary** (`./bwa`):

```bash
make -j && tests/smoke_align.sh ./bwa && tests/golden_sam.sh ./bwa && tests/golden_sampe.sh ./bwa && tests/cli_aux.sh ./bwa
```

**CMake build** (`build/bwa`):

```bash
cmake -S . -B build -DBUILD_TESTING=ON && cmake --build build && ctest --test-dir build --output-on-failure
```

Smoke and golden scripts live under `tests/`; auxiliary CLI checks are in `tests/cli_aux.sh`.

## Manual page

The troff manual page ships as [man/bwa.1](https://github.com/yassineS/bwa-neo/blob/main/man/bwa.1). From a checkout:

```bash
man ./man/bwa.1
```

Update `man/bwa.1` when you change user-visible command-line behaviour.
