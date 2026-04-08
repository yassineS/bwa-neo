#!/usr/bin/env bash
# Golden tests for bwa auxiliary subcommands (qualfa2fq, xa2multi, postalt, typehla-selctg, typehla).
set -euo pipefail
BWA_INPUT="${1:?usage: cli_aux.sh /path/to/bwa}"
BWA="$(cd "$(dirname "$BWA_INPUT")" && pwd)/$(basename "$BWA_INPUT")"
ROOT="$(cd "$(dirname "$0")" && pwd)"
FX="${ROOT}/fixtures/cli_aux"

cmp_qualfa() {
	"$BWA" qualfa2fq "$FX/tiny.fa" "$FX/tiny.qual" 2>/dev/null | cmp -s - "$FX/expected_qualfa.fq"
}

cmp_xa2multi() {
	"$BWA" xa2multi <"$FX/xa_in.sam" 2>/dev/null | cmp -s - "$FX/xa_expected.sam"
}

cmp_selctg() {
	"$BWA" typehla-selctg HLA-A "$FX/hla_exons.bed" "$FX/hla_ctg.sam.gz" 2>/dev/null \
		| cmp -s - "$FX/expected_selctg.txt"
}

test_postalt_version() {
	test "$("$BWA" postalt -v 2>/dev/null)" = "r985"
}

cmp_postalt_stream() {
	"$BWA" postalt "$FX/tiny_alt.sam" "$FX/tiny_aln.sam" 2>/dev/null | cmp -s - "$FX/tiny_aln.sam"
}

test_typehla_version() {
	test "$("$BWA" typehla -v 2>/dev/null)" = "r19"
}

cmp_typehla_gt() {
	"$BWA" typehla "$FX/typehla_exon_to_contig.sam.gz" 2>/dev/null \
		| cmp -s - "$FX/expected_typehla.gt"
}

cmp_qualfa || {
	echo "cli_aux FAIL: qualfa2fq" >&2
	exit 1
}
cmp_xa2multi || {
	echo "cli_aux FAIL: xa2multi" >&2
	exit 1
}
cmp_selctg || {
	echo "cli_aux FAIL: typehla-selctg" >&2
	exit 1
}
test_postalt_version || {
	echo "cli_aux FAIL: postalt -v" >&2
	exit 1
}
cmp_postalt_stream || {
	echo "cli_aux FAIL: postalt stream" >&2
	exit 1
}
test_typehla_version || {
	echo "cli_aux FAIL: typehla -v" >&2
	exit 1
}
cmp_typehla_gt || {
	echo "cli_aux FAIL: typehla genotype output" >&2
	exit 1
}

echo "cli_aux OK"
