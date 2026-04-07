cmake_minimum_required(VERSION 3.16)
project(bwa-neo LANGUAGES C CXX)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

option(BWA_NEO_BUILD_BWA_MEM2 "Fetch and build bwa-mem2 into third_party/bwa-mem2" OFF)
option(BWA_NEO_ENABLE_ASAN "Build with AddressSanitizer" OFF)

if(BWA_NEO_ENABLE_ASAN)
  add_compile_options(-fsanitize=address -fno-omit-frame-pointer -g)
  add_link_options(-fsanitize=address)
endif()

set(BWA_NEO_LIB_SRCS
  utils.c kthread.c kstring.c ksw.c bwt.c bntseq.c bwa.c bwamem.c bwamem_pair.c bwamem_extra.c
  malloc_wrap.c QSufSort.c bwt_gen.c rope.c rle.c is.c bwtindex.c
)

set(BWA_NEO_EXE_SRCS
  bwashm.c bwase.c bwaseqio.c bwtgap.c bwtaln.c bamlite.c bwape.c kopen.c pemerge.c maxk.c
  bwtsw2_core.c bwtsw2_main.c bwtsw2_aux.c bwt_lite.c bwtsw2_chain.c fastmap.c bwtsw2_pair.c
  main.c
)

add_compile_definitions(HAVE_PTHREAD USE_MALLOC_WRAPPERS)

if(APPLE)
  # clock_gettime may need this on older macOS SDKs when linking
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
  list(APPEND BWA_NEO_EXTRA_LIBS rt)
endif()

add_library(bwa_core STATIC ${BWA_NEO_LIB_SRCS})
target_compile_options(bwa_core PRIVATE -Wall -Wno-unused-function -O3)
target_link_libraries(bwa_core PUBLIC m z pthread ${BWA_NEO_EXTRA_LIBS})

add_executable(bwa ${BWA_NEO_EXE_SRCS})
target_compile_options(bwa PRIVATE -Wall -Wno-unused-function -O3)
target_link_libraries(bwa PRIVATE bwa_core m z pthread ${BWA_NEO_EXTRA_LIBS})

include(GNUInstallDirs)
install(TARGETS bwa RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

include(CTest)
if(BUILD_TESTING)
  add_subdirectory(tests)
endif()

if(BWA_NEO_BUILD_BWA_MEM2)
  include(cmake/BwaMem2.cmake)
endif()
