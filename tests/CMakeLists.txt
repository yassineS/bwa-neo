include(FetchContent)
FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/archive/refs/tags/v1.14.0.zip
)
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

add_executable(bwa_neo_unit test_unit.cpp)
target_link_libraries(bwa_neo_unit PRIVATE GTest::gtest_main)
target_compile_features(bwa_neo_unit PRIVATE cxx_std_17)

add_test(NAME unit COMMAND bwa_neo_unit)

add_test(NAME smoke_align COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/smoke_align.sh $<TARGET_FILE:bwa>)
set_tests_properties(smoke_align PROPERTIES WORKING_DIRECTORY ${CMAKE_BINARY_DIR})
