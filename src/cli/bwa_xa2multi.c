/* xa2multi.pl — expand XA supplementary alignments (stdin/stdout). */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "bwa_aux.h"

static void emit_xa_supp(char **f, int n)
{
	const char *s;
	int i;

	for (i = 11; i < n; ++i)
		if (strncmp(f[i], "XA:Z:", 5) == 0)
			break;
	if (i >= n)
		return;
	s = f[i] + 5;

	while (*s && *s != '\n') {
		char ctg[512], cigar[2048];
		char strand;
		long pos;
		int nm;
		const char *p = s;
		char *end;
		size_t clen;

		end = strchr(p, ',');
		if (!end)
			break;
		clen = (size_t)(end - p);
		if (clen >= sizeof(ctg))
			break;
		memcpy(ctg, p, clen);
		ctg[clen] = 0;
		p = end + 1;
		if (*p != '+' && *p != '-')
			break;
		strand = *p++;
		pos = strtol(p, &end, 10);
		if (p == end || *end != ',')
			break;
		p = end + 1;
		end = strchr(p, ',');
		if (!end)
			break;
		clen = (size_t)(end - p);
		if (clen >= sizeof(cigar))
			break;
		memcpy(cigar, p, clen);
		cigar[clen] = 0;
		p = end + 1;
		nm = (int)strtol(p, &end, 10);
		p = end;
		if (*p == ';')
			++p;
		s = p;

		{
			unsigned flag = (unsigned)strtoul(f[1], NULL, 0);
			const char *rnext = f[6];
			const char *mchr = (strcmp(rnext, "=") == 0) ? f[2] : rnext;
			const char *mchr_ = (strcmp(mchr, ctg) == 0) ? "=" : mchr;
			int neg = (strand == '-');
			unsigned newflag = 0x100u | (flag & 0x6e9u) | (neg ? 0x10u : 0u);
			const char *seq = f[9];
			const char *qual = f[10];
			size_t L, j;

			printf("%s\t%u\t%s\t%ld\t0\t%s\t%s\t%s\t%s\t", f[0], newflag, ctg, labs(pos), cigar, mchr_, f[7], f[8]);
			if (((flag & 0x10) != 0) ^ neg) {
				L = strlen(seq);
				for (j = 0; j < L; ++j) {
					int c = (unsigned char)seq[L - 1 - j];
					if (c == 'A' || c == 'a')
						c = 'T';
					else if (c == 'C' || c == 'c')
						c = 'G';
					else if (c == 'G' || c == 'g')
						c = 'C';
					else if (c == 'T' || c == 't')
						c = 'A';
					putchar(c);
				}
				putchar('\t');
				L = strlen(qual);
				for (j = 0; j < L; ++j)
					putchar(qual[L - 1 - j]);
			} else {
				fputs(seq, stdout);
				putchar('\t');
				fputs(qual, stdout);
			}
			printf("\tNM:i:%d\n", nm);
		}
	}
}

static void process_line(char *line)
{
	char *fields[384];
	int n = 0;
	char *p, *q;
	int has_xa = 0;
	int i;

	for (p = line, q = line; *q; ++q) {
		if (*q == '\t') {
			*q = 0;
			if (n < 384)
				fields[n++] = p;
			p = q + 1;
		} else if (*q == '\n' || *q == '\r') {
			*q = 0;
			break;
		}
	}
	if (n < 384)
		fields[n++] = p;

	if (n < 11) {
		for (i = 0; i < n; ++i) {
			if (i)
				putchar('\t');
			fputs(fields[i], stdout);
		}
		putchar('\n');
		return;
	}

	for (i = 11; i < n; ++i)
		if (strncmp(fields[i], "XA:Z:", 5) == 0)
			has_xa = 1;

	for (i = 0; i < n; ++i) {
		if (i)
			putchar('\t');
		fputs(fields[i], stdout);
	}
	putchar('\n');

	if (!has_xa)
		return;

	emit_xa_supp(fields, n);
}

int bwa_xa2multi(int argc, char *argv[])
{
	char buf[65536];
	(void)argc;
	(void)argv;
	while (fgets(buf, sizeof(buf), stdin))
		process_line(buf);
	return 0;
}
