# Optional bwa-mem2 build (separate binary: bwa-mem2) via ExternalProject.
include(ExternalProject)

set(BWA_MEM2_SRC "${CMAKE_SOURCE_DIR}/third_party/bwa-mem2")
if(NOT EXISTS "${BWA_MEM2_SRC}/Makefile")
  message(FATAL_ERROR "bwa-mem2 sources not found. Run: scripts/fetch-bwa-mem2.sh")
endif()

ExternalProject_Add(
  bwa_mem2_build
  SOURCE_DIR "${BWA_MEM2_SRC}"
  CONFIGURE_COMMAND ""
  BUILD_COMMAND ${CMAKE_MAKE_PROGRAM} -j
  BUILD_IN_SOURCE TRUE
  INSTALL_COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${BWA_MEM2_SRC}/bwa-mem2"
    "${CMAKE_BINARY_DIR}/bwa-mem2"
)

add_custom_target(bwa-mem2 ALL DEPENDS bwa_mem2_build)
