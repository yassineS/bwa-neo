/* qualfa2fq.pl — FASTA + QUAL numbers to FASTQ */
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <zlib.h>

#include "bwa_aux.h"
#include "kseq.h"
#include "utils.h"

KSEQ_INIT(gzFile, err_gzread)

int bwa_qualfa2fq(int argc, char *argv[])
{
	gzFile fas, faq;
	kseq_t *ks, *kq;

	if (argc != 3) {
		fprintf(stderr, "Usage: bwa qualfa2fq <in.fasta> <in.qual>\n");
		return 1;
	}
	fas = xzopen(argv[1], "r");
	faq = xzopen(argv[2], "r");
	ks = kseq_init(fas);
	kq = kseq_init(faq);

	while (kseq_read(ks) >= 0 && kseq_read(kq) >= 0) {
		const char *q;
		size_t j = 0;
		int first = 1;

		err_printf("@%s\n", ks->name.s);
		fputs(ks->seq.s, stdout);
		err_printf("\n+\n");
		q = kq->seq.s;
		for (;;) {
			while (*q && isspace((unsigned char)*q))
				++q;
			if (!*q)
				break;
			{
				char *endp;
				long v = strtol(q, &endp, 10);
				if (endp == q)
					break;
				q = endp;
				if (!first && j % 60 == 0)
					putchar('\n');
				first = 0;
				if (v < 0)
					v = 0;
				if (v > 93)
					v = 93;
				putchar((int)(33 + v));
				++j;
			}
		}
		putchar('\n');
	}

	if (kseq_read(ks) >= 0 || kseq_read(kq) >= 0) {
		fprintf(stderr, "[qualfa2fq] FASTA and QUAL have different number of records\n");
		kseq_destroy(ks);
		kseq_destroy(kq);
		gzclose(fas);
		gzclose(faq);
		return 1;
	}
	kseq_destroy(ks);
	kseq_destroy(kq);
	gzclose(fas);
	gzclose(faq);
	return 0;
}
