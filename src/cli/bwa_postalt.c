/* ALT SAM companion: consume alt.sam, stream alignment SAM (bwakit pass-through until full liftover port). */
#include <stdio.h>
#include <string.h>
#include <zlib.h>

#include "bwa_aux.h"
#include "kseq.h"
#include "utils.h"

KSTREAM_INIT(gzFile, err_gzread, 16384)

#define VER "r985"

int bwa_postalt(int argc, char *argv[])
{
	int opt = 1;
	const char *aln_path;
	gzFile fa, galn;
	kstream_t *ks;
	kstring_t line = {0, 0, 0};
	int dret = 0;

	while (opt < argc && argv[opt][0] == '-' && argv[opt][1]) {
		if (!strcmp(argv[opt], "-v")) {
			puts(VER);
			return 0;
		} else if (!strcmp(argv[opt], "-p") && opt + 1 < argc)
			opt += 2;
		else if (!strcmp(argv[opt], "-r") && opt + 1 < argc)
			opt += 2;
		else {
			fprintf(stderr, "[postalt] unknown option %s\n", argv[opt]);
			return 1;
		}
	}
	if (opt >= argc) {
		fprintf(stderr, "Usage: bwa postalt [options] <alt.sam> [aln.sam]\n");
		return 1;
	}

	fprintf(stderr,
		"[postalt] Warning: streaming alignment SAM without ALT liftover / mapQ adjustment.\n"
		"[postalt]          Full parity with historical bwakit bwa-postalt.js is not implemented yet.\n");

	fa = xzopen(argv[opt], "r");
	ks = ks_init(fa);
	while (ks_getuntil(ks, KS_SEP_LINE, &line, &dret) >= 0)
		;
	ks_destroy(ks);
	gzclose(fa);
	free(line.s);
	line.s = 0;
	line.l = line.m = 0;

	aln_path = (opt + 1 < argc) ? argv[opt + 1] : "-";
	galn = xzopen(aln_path, "r");
	ks = ks_init(galn);
	while (ks_getuntil(ks, KS_SEP_LINE, &line, &dret) >= 0) {
		if (line.l)
			printf("%s\n", line.s);
	}
	ks_destroy(ks);
	gzclose(galn);
	free(line.s);
	return 0;
}
