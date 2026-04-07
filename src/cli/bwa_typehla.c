/* typeHLA.js — C port in progress; use bwakit/typeHLA.js with k8 for full parity until complete. */
#include <stdio.h>
#include <string.h>

#include "bwa_aux.h"

#define TH_VER "r19"

int bwa_typehla(int argc, char *argv[])
{
	int opt = 1;
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
	fprintf(stderr,
		"[typehla] Full HLA genotyping port is not yet merged; run: k8 bwakit/typeHLA.js ...\n"
		"          (Tracking: genotype scoring from exon–contig SAM matches bwakit r19.)\n");
	(void)argc;
	return 1;
}
