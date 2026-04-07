CC=			gcc
#CC=			clang --analyze
CFLAGS=		-g -Wall -Wno-unused-function -O3
WRAP_MALLOC=-DUSE_MALLOC_WRAPPERS
AR=			ar
DFLAGS=		-DHAVE_PTHREAD $(WRAP_MALLOC)
SRC_DIRS=	src/core src/index src/backtrack src/mem src/cli
LIB_SRCS=	src/core/utils.c src/core/kthread.c src/core/kstring.c src/core/ksw.c src/core/malloc_wrap.c \
			src/core/QSufSort.c src/core/rope.c src/core/rle.c src/core/is.c src/index/bwt.c src/index/bntseq.c \
			src/index/bwa.c src/index/bwt_gen.c src/index/bwtindex.c src/mem/bwamem.c src/mem/bwamem_pair.c \
			src/mem/bwamem_extra.c
EXE_SRCS=	src/backtrack/bwashm.c src/backtrack/bwase.c src/backtrack/bwaseqio.c src/backtrack/bwtgap.c \
			src/backtrack/bwtaln.c src/backtrack/bwape.c src/backtrack/bwtsw2_core.c src/backtrack/bwtsw2_main.c \
			src/backtrack/bwtsw2_aux.c src/backtrack/bwtsw2_chain.c src/backtrack/bwtsw2_pair.c src/index/bwt_lite.c \
			src/mem/fastmap.c src/core/bamlite.c src/core/kopen.c src/core/pemerge.c src/core/maxk.c
LOBJS=		$(patsubst %.c,%.o,$(LIB_SRCS))
AOBJS=		$(patsubst %.c,%.o,$(EXE_SRCS))
MAIN_OBJ=	src/cli/main.o
EXAMPLE_OBJ=src/cli/example.o
PROG=		bwa
INCLUDES=	-Iinclude/bwa
LIBS=		-lm -lz -lpthread

ifeq ($(shell uname -s),Linux)
	LIBS += -lrt
endif
ifeq ($(shell uname -s),GNU/kFreeBSD)
	LIBS += -lrt
endif

ifneq ($(asan),)
	CFLAGS+=-fsanitize=address
	LIBS+=-fsanitize=address -ldl
endif

%.o: %.c
		$(CC) -c $(CFLAGS) $(DFLAGS) $(INCLUDES) $(CPPFLAGS) $< -o $@

all:$(PROG)

bwa:libbwa.a $(AOBJS) $(MAIN_OBJ)
		$(CC) $(CFLAGS) $(LDFLAGS) $(AOBJS) $(MAIN_OBJ) -o $@ -L. -lbwa $(LIBS)

bwamem-lite:libbwa.a $(EXAMPLE_OBJ)
		$(CC) $(CFLAGS) $(LDFLAGS) $(EXAMPLE_OBJ) -o $@ -L. -lbwa $(LIBS)

libbwa.a:$(LOBJS)
		$(AR) -csru $@ $(LOBJS)

clean:
		rm -f gmon.out a.out $(PROG) *~ *.a bwamem-lite
		rm -f $(LOBJS) $(AOBJS) $(MAIN_OBJ) $(EXAMPLE_OBJ)

depend:
	( LC_ALL=C ; export LC_ALL; makedepend -Y -- $(CFLAGS) $(DFLAGS) $(CPPFLAGS) $(INCLUDES) -- $(LIB_SRCS) $(EXE_SRCS) src/cli/main.c src/cli/example.c )
