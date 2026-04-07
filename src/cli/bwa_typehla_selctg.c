/* typeHLA-selctg.js — select contigs overlapping HLA exons */
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <zlib.h>

#include "bwa_aux.h"
#include "khash.h"
#include "kseq.h"
#include "kvec.h"
#include "utils.h"

KSTREAM_INIT(gzFile, err_gzread, 16384)

typedef struct {
	int a, b;
} intpair_t;

typedef kvec_t(intpair_t) intpair_v;

KHASH_MAP_INIT_STR(sel_bed, intpair_v)

typedef struct {
	int as, xs, ovlp;
} sel_hit_t;

typedef kvec_t(sel_hit_t) sel_hit_v;

KHASH_MAP_INIT_STR(sel_ctg, sel_hit_v)

static int sel_hit_cmp(const void *aa, const void *bb)
{
	const sel_hit_t *a = (const sel_hit_t *)aa;
	const sel_hit_t *b = (const sel_hit_t *)bb;
	return (b->as > a->as) - (b->as < a->as);
}

static void iv_push(intpair_v *v, int a, int b)
{
	intpair_t x = {a, b};
	kv_push(intpair_t, *v, x);
}

int bwa_typehla_selctg(int argc, char *argv[])
{
	khash_t(sel_bed) *hbed;
	khash_t(sel_ctg) *hctg;
	gzFile fp;
	kstream_t *ks = NULL;
	kstring_t line = {0, 0, 0};
	int dret = 0, ret;
	const char *gene;
	int min_ovlp = 30;
	khint_t k;

	if (argc < 4) {
		fprintf(stderr, "Usage: bwa typehla-selctg <HLA-gene> <HLA-ALT-exons.bed> <ctg-to-ALT.sam.gz> [min_ovlp=30]\n");
		return 1;
	}
	gene = argv[1];
	if (argc >= 5)
		min_ovlp = atoi(argv[4]);

	hbed = kh_init(sel_bed);
	hctg = kh_init(sel_ctg);

	fp = xzopen(argv[2], "r");
	ks = ks_init(fp);
	while (ks_getuntil(ks, KS_SEP_LINE, &line, &dret) >= 0) {
		char *ctgn, *p, *save = NULL;
		long start, end;
		char *g4;

		if (line.l == 0)
			continue;
		ctgn = strtok_r(line.s, "\t", &save);
		if (!ctgn)
			continue;
		p = strtok_r(NULL, "\t", &save);
		if (!p)
			continue;
		start = atol(p);
		p = strtok_r(NULL, "\t", &save);
		if (!p)
			continue;
		end = atol(p);
		g4 = strtok_r(NULL, "\t", &save);
		if (!g4 || strcmp(g4, gene) != 0)
			continue;

		k = kh_get(sel_bed, hbed, ctgn);
		if (k == kh_end(hbed)) {
			char *key = strdup(ctgn);
			intpair_v v;
			kv_init(v);
			iv_push(&v, (int)start, (int)end);
			k = kh_put(sel_bed, hbed, key, &ret);
			kh_val(hbed, k) = v;
		} else {
			intpair_v *vp = &kh_val(hbed, k);
			iv_push(vp, (int)start, (int)end);
		}
	}
	if (ks)
		ks_destroy(ks);
	ks = NULL;
	gzclose(fp);
	free(line.s);
	line.s = 0;
	line.l = line.m = 0;

	fp = xzopen(argv[3], "r");
	ks = ks_init(fp);
	while (ks_getuntil(ks, KS_SEP_LINE, &line, &dret) >= 0) {
		char *qname, *rname, *pos_s, *cigar, *save = NULL;
		long start, end;
		char *p;
		int as = INT_MIN, xs = INT_MIN;
		khint_t kb;
		intpair_v *ivp;
		size_t i;

		if (line.l == 0 || line.s[0] == '@')
			continue;

		qname = strtok_r(line.s, "\t", &save);
		if (!qname)
			continue;
		strtok_r(NULL, "\t", &save);
		rname = strtok_r(NULL, "\t", &save);
		if (!rname)
			continue;
		pos_s = strtok_r(NULL, "\t", &save);
		if (!pos_s)
			continue;
		strtok_r(NULL, "\t", &save);
		cigar = strtok_r(NULL, "\t", &save);
		if (!cigar)
			continue;

		kb = kh_get(sel_bed, hbed, rname);
		if (kb == kh_end(hbed))
			continue;
		ivp = &kh_val(hbed, kb);

		start = atol(pos_s) - 1;
		end = start;
		for (p = cigar; *p;) {
			long len = strtol(p, &p, 10);
			if (*p == 'M' || *p == 'D') {
				end += len;
				++p;
			} else if (*p == 'I' || *p == 'S' || *p == 'H' || *p == 'N')
				++p;
			else
				++p;
		}

		{
			int max_ovlp = 0;
			for (i = 0; i < ivp->n; ++i) {
				int ml = ivp->a[i].a > (int)start ? ivp->a[i].a : (int)start;
				int mr = ivp->a[i].b < (int)end ? ivp->a[i].b : (int)end;
				int o = mr - ml;
				if (o > max_ovlp)
					max_ovlp = o;
			}
			p = strstr(line.s, "\tAS:i:");
			if (p)
				as = (int)strtol(p + 5, NULL, 10);
			p = strstr(line.s, "\tXS:i:");
			if (p)
				xs = (int)strtol(p + 5, NULL, 10);

			k = kh_get(sel_ctg, hctg, qname);
			if (k == kh_end(hctg)) {
				char *key = strdup(qname);
				sel_hit_v hv;
				sel_hit_t sh;
				kv_init(hv);
				sh.as = as;
				sh.xs = xs;
				sh.ovlp = max_ovlp;
				kv_push(sel_hit_t, hv, sh);
				k = kh_put(sel_ctg, hctg, key, &ret);
				kh_val(hctg, k) = hv;
			} else {
				sel_hit_v *hvp = &kh_val(hctg, k);
				sel_hit_t sh;
				sh.as = as;
				sh.xs = xs;
				sh.ovlp = max_ovlp;
				kv_push(sel_hit_t, *hvp, sh);
			}
		}
	}
	if (ks)
		ks_destroy(ks);
	gzclose(fp);
	free(line.s);

	for (k = kh_begin(hctg); k != kh_end(hctg); ++k) {
		if (!kh_exist(hctg, k))
			continue;
		{
			sel_hit_v *hv = &kh_val(hctg, k);
			size_t i;
			int rejected = 0;
			if (hv->n == 0)
				continue;
			qsort(hv->a, hv->n, sizeof(sel_hit_t), sel_hit_cmp);
			for (i = 0; i < hv->n && hv->a[i].as == hv->a[0].as; ++i) {
				if (hv->a[0].ovlp < min_ovlp || hv->a[i].as == hv->a[i].xs)
					rejected = 1;
			}
			if (!rejected)
				puts(kh_key(hctg, k));
		}
	}

	for (k = kh_begin(hbed); k != kh_end(hbed); ++k) {
		if (!kh_exist(hbed, k)) {
			continue;
		}
		kv_destroy(kh_val(hbed, k));
		free((char *)kh_key(hbed, k));
	}
	kh_destroy(sel_bed, hbed);

	for (k = kh_begin(hctg); k != kh_end(hctg); ++k) {
		if (kh_exist(hctg, k)) {
			kv_destroy(kh_val(hctg, k));
			free((char *)kh_key(hctg, k));
		}
	}
	kh_destroy(sel_ctg, hctg);
	return 0;
}
