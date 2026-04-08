/* HLA genotyping placeholder: accepts exon-to-contig SAM.gz, produces no GT lines until full port. */
#include <stdio.h>
#include <string.h>
#include <zlib.h>

#include "bwa_aux.h"
#include "kseq.h"
#include "utils.h"

KSTREAM_INIT(gzFile, err_gzread, 16384)

#define TH_VER "r19"

int bwa_typehla(int argc, char *argv[])
{
	int opt = 1;
	const char *path;
	gzFile fp;
	kstream_t *ks;
	kstring_t line = {0, 0, 0};
	int dret = 0;

	while (opt < argc && argv[opt][0] == '-' && argv[opt][1]) {
		if (!strcmp(argv[opt], "-v")) {
			puts(TH_VER);
			return 0;
		}
		++opt;
	}
	if (opt >= argc) {
		fprintf(stderr, "Usage: bwa typehla [options] <exon-to-contig.sam.gz>\n");
		return 1;
	}
	path = argv[opt];
	fp = xzopen(path, "r");
	ks = ks_init(fp);
	while (ks_getuntil(ks, KS_SEP_LINE, &line, &dret) >= 0)
		;
	ks_destroy(ks);
	gzclose(fp);
	free(line.s);
	fprintf(stderr,
		"[typehla] Full HLA genotyping is not implemented in C yet; no GT lines written.\n");
	return 0;
}
