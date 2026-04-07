/* bwa-postalt.js — C port in progress; use k8 bwakit/bwa-postalt.js for full ALT liftover until complete. */
#include <stdio.h>
#include <string.h>

#include "bwa_aux.h"

#define VER "r985"

int bwa_postalt(int argc, char *argv[])
{
	int opt = 1;
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
		"[postalt] Full ALT postprocessing port is not yet merged; run: k8 bwakit/bwa-postalt.js ...\n"
		"          (Matches GRCh38 ALT / XA liftover and mapQ logic from bwakit r985.)\n");
	return 1;
}
