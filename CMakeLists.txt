cmake_minimum_required(VERSION 3.16)
project(bwa-neo LANGUAGES C)

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
  src/core/utils.c
  src/core/kthread.c
  src/core/kstring.c
  src/core/ksw.c
  src/core/malloc_wrap.c
  src/core/QSufSort.c
  src/core/rope.c
  src/core/rle.c
  src/core/is.c
  src/index/bwt.c
  src/index/bntseq.c
  src/index/bwa.c
  src/index/bwt_gen.c
  src/index/bwtindex.c
  src/mem/bwamem.c
  src/mem/bwamem_pair.c
  src/mem/bwamem_extra.c
)

set(BWA_NEO_EXE_SRCS
  src/backtrack/bwashm.c
  src/backtrack/bwase.c
  src/backtrack/bwaseqio.c
  src/backtrack/bwtgap.c
  src/backtrack/bwtaln.c
  src/backtrack/bwape.c
  src/backtrack/bwtsw2_core.c
  src/backtrack/bwtsw2_main.c
  src/backtrack/bwtsw2_aux.c
  src/backtrack/bwtsw2_chain.c
  src/backtrack/bwtsw2_pair.c
  src/index/bwt_lite.c
  src/mem/fastmap.c
  src/core/bamlite.c
  src/core/kopen.c
  src/core/pemerge.c
  src/core/maxk.c
  src/cli/bwa_xa2multi.c
  src/cli/bwa_qualfa2fq.c
  src/cli/bwa_postalt.c
  src/cli/bwa_typehla_selctg.c
  src/cli/bwa_typehla.c
  src/cli/main.c
)

add_compile_definitions(HAVE_PTHREAD USE_MALLOC_WRAPPERS)

if(APPLE)
  # clock_gettime may need this on older macOS SDKs when linking
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
  list(APPEND BWA_NEO_EXTRA_LIBS rt)
endif()

add_library(bwa_core STATIC ${BWA_NEO_LIB_SRCS})
target_compile_options(bwa_core PRIVATE -Wall -Wno-unused-function -O3)
target_include_directories(bwa_core PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include/bwa)
target_link_libraries(bwa_core PUBLIC m z pthread ${BWA_NEO_EXTRA_LIBS})

add_executable(bwa ${BWA_NEO_EXE_SRCS})
target_compile_options(bwa PRIVATE -Wall -Wno-unused-function -O3)
target_include_directories(bwa PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include/bwa)
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
