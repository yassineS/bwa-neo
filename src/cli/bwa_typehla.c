/* typeHLA.js C port: infer HLA genotype pairs from exon-to-contig SAM.gz */
#include <ctype.h>
#include <stdint.h>
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

#define TH_VER "r19"

typedef struct {
	int contig, gene, exon;
	int ts, te, nm, lr, qs, qe, ql;
} th_hit_t;

typedef kvec_t(th_hit_t) th_hit_v;
typedef kvec_t(int) int_v;

typedef struct {
	int s, e, ql, mm;
} perf_seg_t;
typedef kvec_t(perf_seg_t) perf_seg_v;

typedef struct {
	int c, g, nm_lr, aln_len;
} exon_hit_t;
typedef kvec_t(exon_hit_t) exon_hit_v;

typedef struct {
	int g1, g2, m;
} tmp_pair_t;
typedef kvec_t(tmp_pair_t) tmp_pair_v;

typedef struct {
	int score14, pri8, i, j, tie;
} out_row_t;
typedef kvec_t(out_row_t) out_row_v;

KHASH_MAP_INIT_STR(th_strmap, int)

static int parse_gene_exon(const char *qname, char **gene_out, int *exon_out)
{
	const char *u = strrchr(qname, '_');
	char *endp = NULL;
	long exon = 0;
	size_t n = 0;
	if (!u || u == qname || !u[1])
		return -1;
	exon = strtol(u + 1, &endp, 10);
	if (*endp != '\0' || exon <= 0)
		return -1;
	n = (size_t)(u - qname);
	*gene_out = (char *)calloc(n + 1, 1);
	memcpy(*gene_out, qname, n);
	(*gene_out)[n] = '\0';
	*exon_out = (int)exon - 1;
	return 0;
}

static int parse_cigar(const char *cigar, int *x_mis, int *ref_span, int clip[2])
{
	const char *p = cigar;
	int x = 0, ref = 0;
	clip[0] = clip[1] = 0;
	while (*p) {
		char *endp = NULL;
		long l = strtol(p, &endp, 10);
		if (endp == p || l < 0)
			return -1;
		p = endp;
		if (*p == 'M') x += (int)l, ref += (int)l;
		else if (*p == 'I') x += (int)l;
		else if (*p == 'D') ref += (int)l;
		else if (*p == 'S' || *p == 'H') clip[x == 0 ? 0 : 1] = (int)l;
		else if (*p == 'N' || *p == 'P' || *p == '=' || *p == 'X') ref += (int)l;
		else return -1;
		++p;
	}
	*x_mis = x;
	*ref_span = ref;
	return 0;
}

static int get_or_add_id(khash_t(th_strmap) *h, int_v *ids, const char *s)
{
	khint_t k = kh_get(th_strmap, h, s);
	int ret = 0;
	if (k != kh_end(h))
		return kh_val(h, k);
	k = kh_put(th_strmap, h, strdup(s), &ret);
	kh_val(h, k) = (int)ids->n;
	kv_push(int, *ids, 1);
	return kh_val(h, k);
}

static int cmp_perf_seg(const void *aa, const void *bb)
{
	const perf_seg_t *a = (const perf_seg_t *)aa;
	const perf_seg_t *b = (const perf_seg_t *)bb;
	return (a->s > b->s) - (a->s < b->s);
}

static uint32_t update_pair(uint32_t x, int m, int is_pri)
{
	int y = ((x >> 14) & 0xff) + m;
	int z = (x >> 22) + (is_pri ? m : 0);
	if (y > 0xff) y = 0xff;
	if (z > 0xff) z = 0xff;
	return (uint32_t)((z << 22) | (y << 14) | ((x & 0x3fff) + ((1 << 6) | is_pri)));
}

static int cmp_out_row(const void *aa, const void *bb)
{
	const out_row_t *a = (const out_row_t *)aa;
	const out_row_t *b = (const out_row_t *)bb;
	if (a->score14 != b->score14) return (a->score14 > b->score14) - (a->score14 < b->score14);
	if (a->pri8 != b->pri8) return (b->pri8 > a->pri8) - (b->pri8 < a->pri8);
	if (a->tie != b->tie) return (a->tie > b->tie) - (a->tie < b->tie);
	if (a->i != b->i) return (a->i > b->i) - (a->i < b->i);
	return (a->j > b->j) - (a->j < b->j);
}

int bwa_typehla(int argc, char *argv[])
{
	int i, j, opt = 1, ret = 1;
	int thres_len = 50, thres_nm = 5, dbg = 0;
	double thres_ratio = 0.8, thres_frac = 0.33;
	const char *path = NULL;
	gzFile fp = NULL;
	kstream_t *ks = NULL;
	kstring_t line = {0, 0, 0};
	int dret = 0;
	khash_t(th_strmap) *gmap = NULL, *cmap = NULL;
	int_v gids, cids;
	th_hit_v hits;
	int max_exon = -1, n_pri_exons = 0;
	int *pri_exon = NULL;
	int *cnt = NULL;
	int *perf_gene_cnt = NULL;
	uint8_t *perf_hash = NULL;
	uint8_t *gene_has_exon = NULL;
	uint32_t *pair = NULL;
	int n_genes = 0, n_contigs = 0;
	char **gene_names = NULL, **contig_names = NULL;
	int *gsub = NULL, *gsuf = NULL;
	int attempt_perf = 0;

	kv_init(gids);
	kv_init(cids);
	kv_init(hits);

	while (opt < argc && argv[opt][0] == '-' && argv[opt][1]) {
		if (!strcmp(argv[opt], "-v")) {
			puts(TH_VER);
			ret = 0;
			goto cleanup;
		} else if (!strcmp(argv[opt], "-d")) dbg = 1;
		else if (!strcmp(argv[opt], "-l") && opt + 1 < argc) thres_len = atoi(argv[++opt]);
		else if (!strcmp(argv[opt], "-n") && opt + 1 < argc) thres_nm = atoi(argv[++opt]);
		else if (!strcmp(argv[opt], "-f") && opt + 1 < argc) thres_frac = atof(argv[++opt]);
		else {
			fprintf(stderr, "Usage: bwa typehla [options] <exon-to-contig.sam.gz>\n");
			fprintf(stderr, "Options: -n INT -l INT -f FLOAT -d -v\n");
			ret = 1;
			goto cleanup;
		}
		++opt;
	}
	if (opt >= argc) {
		fprintf(stderr, "Usage: bwa typehla [options] <exon-to-contig.sam.gz>\n");
		ret = 1;
		goto cleanup;
	}
	path = argv[opt];

	gmap = kh_init(th_strmap);
	cmap = kh_init(th_strmap);
	fp = xzopen(path, "r");
	ks = ks_init(fp);
	while (ks_getuntil(ks, KS_SEP_LINE, &line, &dret) >= 0) {
		char *s = line.s, *save = NULL;
		char *orig = strdup(line.s);
		char *qname, *flag_s, *rname, *pos_s, *mapq_s, *cigar;
		int flag = 0, ts = 0, te = 0, x = 0, nm = 0, lr = 0, qs = 0, qe = 0, ql = 0;
		int clip[2] = {0, 0}, tl = 0;
		char *gene = NULL;
		int exon = -1, gid = -1, cid = -1;
		khint_t ksq;

		if (line.l == 0) continue;
		if (s[0] == '@') {
			if (!strncmp(s, "@SQ\t", 4)) {
				char *sn = strstr(s, "\tSN:");
				char *ln = strstr(s, "\tLN:");
				if (sn && ln) {
					char name[512];
					long xln;
					char *se = strchr(sn + 4, '\t');
					size_t n = se ? (size_t)(se - (sn + 4)) : strlen(sn + 4);
					if (n >= sizeof(name)) n = sizeof(name) - 1;
					memcpy(name, sn + 4, n);
					name[n] = '\0';
					cid = get_or_add_id(cmap, &cids, name);
					xln = strtol(ln + 4, NULL, 10);
					if (cid >= 0 && cid < (int)cids.n)
						cids.a[cid] = (int)xln;
				}
			}
			free(orig);
			continue;
		}

		qname = strtok_r(s, "\t", &save);
		flag_s = strtok_r(NULL, "\t", &save);
		rname = strtok_r(NULL, "\t", &save);
		pos_s = strtok_r(NULL, "\t", &save);
		mapq_s = strtok_r(NULL, "\t", &save);
		cigar = strtok_r(NULL, "\t", &save);
		(void)mapq_s;
		if (!qname || !flag_s || !rname || !pos_s || !cigar || rname[0] == '*')
		{
			free(orig);
			continue;
		}

		if (parse_gene_exon(qname, &gene, &exon) != 0) {
			free(gene);
			free(orig);
			continue;
		}
		flag = atoi(flag_s);
		if (parse_cigar(cigar, &x, &te, clip) != 0) {
			free(gene);
			free(orig);
			continue;
		}
		ts = atoi(pos_s) - 1;
		te += ts;
		ksq = kh_get(th_strmap, cmap, rname);
		if (ksq == kh_end(cmap)) {
			free(gene);
			free(orig);
			continue;
		}
		cid = kh_val(cmap, ksq);
		tl = (cid >= 0 && cid < (int)cids.n) ? cids.a[cid] : 0;
		{
			char *nm_s = strstr(orig, "\tNM:i:");
			if (nm_s) nm = atoi(nm_s + 6);
		}
		lr = (ts < clip[0] ? ts : clip[0]) + ((tl - te) < clip[1] ? (tl - te) : clip[1]);
		ql = clip[0] + x + clip[1];
		if (flag & 16) qs = clip[1], qe = ql - clip[0];
		else qs = clip[0], qe = ql - clip[1];

		gid = get_or_add_id(gmap, &gids, gene);
		(void)get_or_add_id(cmap, &cids, rname);
		if (exon > max_exon) max_exon = exon;
		{
			th_hit_t h;
			h.contig = cid; h.gene = gid; h.exon = exon;
			h.ts = ts; h.te = te; h.nm = nm; h.lr = lr;
			h.qs = qs; h.qe = qe; h.ql = ql;
			kv_push(th_hit_t, hits, h);
		}
		free(gene);
		free(orig);
	}
	ks_destroy(ks); ks = NULL;
	gzclose(fp); fp = NULL;
	free(line.s); line.s = NULL; line.l = line.m = 0;

	n_genes = (int)gids.n;
	n_contigs = (int)cids.n;
	if (n_genes == 0 || hits.n == 0 || max_exon < 0) {
		ret = 0;
		goto cleanup;
	}
	gene_names = (char **)calloc((size_t)n_genes, sizeof(char *));
	contig_names = (char **)calloc((size_t)n_contigs, sizeof(char *));
	for (khint_t k = kh_begin(gmap); k != kh_end(gmap); ++k) if (kh_exist(gmap, k)) gene_names[kh_val(gmap, k)] = (char *)kh_key(gmap, k);
	for (khint_t k = kh_begin(cmap); k != kh_end(cmap); ++k) if (kh_exist(cmap, k)) contig_names[kh_val(cmap, k)] = (char *)kh_key(cmap, k);

	pri_exon = (int *)calloc((size_t)(max_exon + 1), sizeof(int));
	cnt = (int *)calloc((size_t)(max_exon + 1), sizeof(int));
	perf_gene_cnt = (int *)calloc((size_t)n_genes, sizeof(int));
	perf_hash = (uint8_t *)calloc((size_t)n_genes, 1);
	gene_has_exon = (uint8_t *)calloc((size_t)n_genes * (size_t)(max_exon + 1), 1);
	pair = (uint32_t *)calloc((size_t)n_genes * (size_t)n_genes, sizeof(uint32_t));
	gsub = (int *)calloc((size_t)n_genes, sizeof(int));
	gsuf = (int *)calloc((size_t)n_genes, sizeof(int));

	for (i = 0; i < (int)hits.n; ++i)
		gene_has_exon[hits.a[i].gene * (max_exon + 1) + hits.a[i].exon] = 1;

	for (int e = 0; e <= max_exon; ++e) {
		int c = 0;
		for (i = 0; i < n_genes; ++i)
			if (gene_has_exon[i * (max_exon + 1) + e]) ++c;
		cnt[e] = c;
	}
	{
		int maxc = 0;
		for (int e = 0; e <= max_exon; ++e) if (cnt[e] > maxc) maxc = cnt[e];
		for (int e = 0; e <= max_exon; ++e) {
			pri_exon[e] = (cnt[e] == maxc && maxc > 0) ? 1 : 0;
			if (pri_exon[e]) ++n_pri_exons;
		}
	}

	for (i = 0; i < n_genes; ++i) {
		const char *g = gene_names[i];
		const char *ast = strchr(g, '*');
		const char *col = ast ? strchr(ast + 1, ':') : NULL;
		const char *p = col ? col + 1 : NULL;
		gsub[i] = p ? atoi(p) : 0;
		gsuf[i] = isalpha((unsigned char)g[strlen(g) - 1]) ? 1 : 0;
	}

	for (i = 0; i < n_genes; ++i) {
		for (int e = 0; e <= max_exon; ++e) {
			perf_seg_v segs;
			int cov = 0, s0 = 0, e0 = 0, have = 0, ql0 = -1;
			kv_init(segs);
			for (j = 0; j < (int)hits.n; ++j) {
				th_hit_t *h = &hits.a[j];
				if (h->gene != i || h->exon != e) continue;
				if (ql0 < 0) ql0 = h->ql;
				if (h->nm + h->lr > 0) continue;
				{
					perf_seg_t ps;
					ps.s = h->qs; ps.e = h->qe; ps.ql = h->ql; ps.mm = h->nm + h->lr;
					kv_push(perf_seg_t, segs, ps);
				}
			}
			if (segs.n) {
				qsort(segs.a, segs.n, sizeof(perf_seg_t), cmp_perf_seg);
				s0 = segs.a[0].s; e0 = segs.a[0].e; have = 1;
				for (size_t z = 1; z < segs.n; ++z) {
					if (segs.a[z].s <= e0) {
						if (segs.a[z].e > e0) e0 = segs.a[z].e;
					} else {
						cov += e0 - s0;
						s0 = segs.a[z].s;
						e0 = segs.a[z].e;
					}
				}
				if (have) cov += e0 - s0;
			}
			if (ql0 >= 0 && cov == ql0 && pri_exon[e]) perf_gene_cnt[i]++;
			kv_destroy(segs);
		}
	}
	for (i = 0; i < n_genes; ++i)
		if (perf_gene_cnt[i] == n_pri_exons) perf_hash[i] = 1;

	{
		int *flt_flag = (int *)calloc((size_t)n_contigs, sizeof(int));
		int *ovlp_len = (int *)calloc((size_t)n_contigs, sizeof(int));
		int l_cons = 0, l_incons = 0;
		for (int e = 0; e <= max_exon; ++e) {
			int *max_len = (int *)calloc((size_t)n_contigs, sizeof(int));
			if (!pri_exon[e]) {
				free(max_len);
				continue;
			}
			for (i = 0; i < (int)hits.n; ++i) {
				th_hit_t *h = &hits.a[i];
				int l;
				if (h->exon != e) continue;
				l = (h->te - h->ts) - (h->nm + h->lr);
				if (l < 1) l = 1;
				if (l > max_len[h->contig]) max_len[h->contig] = l;
				flt_flag[h->contig] |= (!perf_hash[h->gene] || (h->nm + h->lr)) ? 1 : 2;
			}
			for (i = 0; i < n_contigs; ++i) ovlp_len[i] += max_len[i];
			free(max_len);
		}
		for (i = 0; i < n_contigs; ++i) {
			if (flt_flag[i] & 2) l_cons += ovlp_len[i];
			else if (flt_flag[i] == 1) l_incons += ovlp_len[i];
		}
		attempt_perf = (l_cons + l_incons) > 0 && ((double)l_incons / (double)(l_cons + l_incons) < thres_frac);

		for (int perf_mode = 0; perf_mode <= (attempt_perf ? 1 : 0); ++perf_mode) {
			uint32_t *pair_local = (uint32_t *)calloc((size_t)n_genes * (size_t)n_genes, sizeof(uint32_t));
			int_v gt_i, gt_j;
			int min_nm_pri = 0x7fffffff;
			kv_init(gt_i); kv_init(gt_j);

			for (int e = 0; e <= max_exon; ++e) {
				exon_hit_v eh;
				int_v ca, ga;
				uint8_t *seen_c = (uint8_t *)calloc((size_t)n_contigs, 1);
				uint8_t *seen_g = (uint8_t *)calloc((size_t)n_genes, 1);
				uint8_t *dropped = (uint8_t *)calloc((size_t)n_contigs, 1);
				uint8_t *valid_g = (uint8_t *)calloc((size_t)n_genes, 1);
				int *max_len = (int *)calloc((size_t)n_contigs, sizeof(int));
				uint8_t *sc = (uint8_t *)calloc((size_t)n_genes * (size_t)n_contigs, 1);
				int is_pri = pri_exon[e] ? 1 : 0;
				int max_max_len = 0;
				kv_init(eh); kv_init(ca); kv_init(ga);
				memset(sc, 0xff, (size_t)n_genes * (size_t)n_contigs);

				for (i = 0; i < (int)hits.n; ++i) {
					th_hit_t *h = &hits.a[i];
					int nm_lr;
					if (h->exon != e) continue;
					if (perf_mode && (flt_flag[h->contig] == 1 || !perf_hash[h->gene])) continue;
					if (!gene_has_exon[h->gene * (max_exon + 1) + e]) continue;
					nm_lr = h->nm + h->lr;
					{
						exon_hit_t xh;
						xh.c = h->contig; xh.g = h->gene; xh.nm_lr = nm_lr; xh.aln_len = h->te - h->ts;
						kv_push(exon_hit_t, eh, xh);
					}
					seen_c[h->contig] = 1;
					seen_g[h->gene] = 1;
				}
				for (i = 0; i < n_contigs; ++i) if (seen_c[i]) kv_push(int, ca, i);
				for (i = 0; i < n_genes; ++i) {
					if (seen_g[i]) {
						kv_push(int, ga, i);
						valid_g[i] = 1;
					}
				}
				if (ca.n == 0 || ga.n == 0) goto exon_cleanup;

				for (i = 0; i < (int)eh.n; ++i) {
					exon_hit_t *x = &eh.a[i];
					size_t idx = (size_t)x->g * (size_t)n_contigs + (size_t)x->c;
					if (!valid_g[x->g]) continue;
					if (x->nm_lr < sc[idx]) sc[idx] = (uint8_t)x->nm_lr;
					if (x->aln_len > max_len[x->c]) max_len[x->c] = x->aln_len;
				}
				for (i = 0; i < (int)ca.n; ++i) if (max_len[ca.a[i]] > max_max_len) max_max_len = max_len[ca.a[i]];
				for (i = 0; i < (int)ca.n; ++i) {
					int c = ca.a[i], mn = 0x7fffffff;
					for (j = 0; j < (int)ga.n; ++j) {
						int g = ga.a[j];
						int v = sc[(size_t)g * (size_t)n_contigs + (size_t)c];
						if (v < mn) mn = v;
					}
					if (mn > thres_nm) dropped[c] = 1;
					if (max_len[c] < thres_len && max_len[c] < (int)(thres_ratio * max_max_len)) dropped[c] = 1;
				}

				if (is_pri || gt_i.n == 0) {
					for (i = 0; i < (int)ga.n; ++i) {
						int gi = ga.a[i], msum = 0;
						for (j = 0; j < (int)ca.n; ++j) {
							int c = ca.a[j];
							if (!dropped[c]) msum += sc[(size_t)gi * (size_t)n_contigs + (size_t)c];
						}
						pair_local[(size_t)gi * (size_t)n_genes + (size_t)gi] =
							update_pair(pair_local[(size_t)gi * (size_t)n_genes + (size_t)gi], msum, is_pri);
						for (int jj = i + 1; jj < (int)ga.n; ++jj) {
							int gj = ga.a[jj], m = 0, a0 = 0, a1 = 0;
							for (j = 0; j < (int)ca.n; ++j) {
								int c = ca.a[j];
								int v1, v2;
								if (dropped[c]) continue;
								v1 = sc[(size_t)gi * (size_t)n_contigs + (size_t)c];
								v2 = sc[(size_t)gj * (size_t)n_contigs + (size_t)c];
								if (v1 < v2) m += v1, ++a0;
								else m += v2, ++a1;
							}
							if (a0 == 0 || a1 == 0) m = 0xff;
							if (gi < gj)
								pair_local[(size_t)gj * (size_t)n_genes + (size_t)gi] =
									update_pair(pair_local[(size_t)gj * (size_t)n_genes + (size_t)gi], m, is_pri);
							else
								pair_local[(size_t)gi * (size_t)n_genes + (size_t)gj] =
									update_pair(pair_local[(size_t)gi * (size_t)n_genes + (size_t)gj], m, is_pri);
						}
					}
				} else {
					tmp_pair_v tps;
					int best = 0xff;
					kv_init(tps);
					for (i = 0; i < (int)gt_i.n; ++i) {
						int g1 = gt_i.a[i], g2 = gt_j.a[i], m = 0, a0 = 0, a1 = 0;
						if (!valid_g[g1] || !valid_g[g2]) continue;
						if (g1 == g2) {
							for (j = 0; j < (int)ca.n; ++j) {
								int c = ca.a[j];
								if (!dropped[c]) m += sc[(size_t)g1 * (size_t)n_contigs + (size_t)c];
							}
						} else {
							for (j = 0; j < (int)ca.n; ++j) {
								int c = ca.a[j], v1, v2;
								if (dropped[c]) continue;
								v1 = sc[(size_t)g1 * (size_t)n_contigs + (size_t)c];
								v2 = sc[(size_t)g2 * (size_t)n_contigs + (size_t)c];
								if (v1 < v2) m += v1, ++a0;
								else m += v2, ++a1;
							}
							if (a0 == 0 || a1 == 0) m = 0xff;
						}
						{
							tmp_pair_t tp;
							tp.g1 = g1; tp.g2 = g2; tp.m = m;
							kv_push(tmp_pair_t, tps, tp);
						}
						if (m < best) best = m;
					}
					if (best < 0xff) {
						for (i = 0; i < (int)tps.n; ++i) {
							tmp_pair_t *tp = &tps.a[i];
							pair_local[(size_t)tp->g1 * (size_t)n_genes + (size_t)tp->g2] =
								update_pair(pair_local[(size_t)tp->g1 * (size_t)n_genes + (size_t)tp->g2], tp->m, is_pri);
						}
					}
					kv_destroy(tps);
				}

exon_cleanup:
				kv_destroy(eh); kv_destroy(ca); kv_destroy(ga);
				free(seen_c); free(seen_g); free(dropped); free(valid_g); free(max_len); free(sc);
			}

			for (i = 0; i < n_genes; ++i) for (j = 0; j <= i; ++j) {
				uint32_t p = pair_local[(size_t)i * (size_t)n_genes + (size_t)j];
				if ((p & 63) == (uint32_t)n_pri_exons) {
					int pri = (int)(p >> 22);
					if (pri < min_nm_pri) min_nm_pri = pri;
				}
			}
			for (i = 0; i < n_genes; ++i) for (j = 0; j <= i; ++j) {
				uint32_t p = pair_local[(size_t)i * (size_t)n_genes + (size_t)j];
				if ((p & 63) == (uint32_t)n_pri_exons && (int)(p >> 22) == min_nm_pri) {
					kv_push(int, gt_i, i);
					kv_push(int, gt_j, j);
				}
			}

			if (perf_mode == 0 || pair == NULL || pair_local[(size_t)gt_i.a[0] * (size_t)n_genes + (size_t)gt_j.a[0]] <
				pair[(size_t)gt_i.a[0] * (size_t)n_genes + (size_t)gt_j.a[0]]) {
				memcpy(pair, pair_local, (size_t)n_genes * (size_t)n_genes * sizeof(uint32_t));
			}
			kv_destroy(gt_i); kv_destroy(gt_j);
			free(pair_local);
		}
		free(flt_flag);
		free(ovlp_len);
	}

	{
		int min_nm = 0x7fffffff;
		out_row_v out;
		kv_init(out);
		for (i = 0; i < n_genes; ++i) for (j = 0; j <= i; ++j) {
			uint32_t p = pair[(size_t)i * (size_t)n_genes + (size_t)j];
			if ((p & 63) == (uint32_t)n_pri_exons) {
				int s = (int)((p >> 14) & 0xff);
				if (s < min_nm) min_nm = s;
			}
		}
		for (i = 0; i < n_genes; ++i) for (j = 0; j <= i; ++j) {
			uint32_t p = pair[(size_t)i * (size_t)n_genes + (size_t)j];
			int s14 = (int)((p >> 14) & 0xff);
			if ((p & 63) == (uint32_t)n_pri_exons && s14 <= min_nm + 1) {
				out_row_t r;
				r.score14 = s14;
				r.pri8 = (int)((p >> 6) & 0xff);
				r.i = i; r.j = j;
				r.tie = ((gsuf[i] + gsuf[j]) << 16) | (gsub[i] + gsub[j]);
				kv_push(out_row_t, out, r);
			}
		}
		qsort(out.a, out.n, sizeof(out_row_t), cmp_out_row);
		for (i = 0; i < (int)out.n; ++i)
			printf("GT\t%s\t%s\t%d\t%d\t%d\n", gene_names[out.a[i].j], gene_names[out.a[i].i],
			       out.a[i].score14 >> 8, out.a[i].score14 & 0xff, out.a[i].pri8);
		kv_destroy(out);
	}
	(void)dbg;
	ret = 0;

cleanup:
	if (ks) ks_destroy(ks);
	if (fp) gzclose(fp);
	free(line.s);
	if (gmap) kh_destroy(th_strmap, gmap);
	if (cmap) kh_destroy(th_strmap, cmap);
	kv_destroy(gids);
	kv_destroy(cids);
	kv_destroy(hits);
	free(pri_exon); free(cnt); free(perf_gene_cnt); free(perf_hash); free(gene_has_exon);
	free(pair); free(gsub); free(gsuf);
	free(gene_names); free(contig_names);
	return ret;
}
