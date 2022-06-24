cmake_minimum_required(VERSION 3.18)
project(CompressionCorrelation VERSION 0.2.0 LANGUAGES CXX)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(default_build_type "Release")
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  message(STATUS "No build type was set. Setting build type to ${default_build_type}.")
  set(CMAKE_BUILD_TYPE ${default_build_type} CACHE 
    STRING "Choose the type to build" FORCE)
endif()
set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release" "MinSizeRel" "RelWithDebInfo")

find_package(LibPressioTools REQUIRED)
find_package(LibDistributed REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(OpenMP REQUIRED)
find_package(MPI REQUIRED)
include(GNUInstallDirs)

add_executable(type_shared shared.cc)
target_link_libraries(type_shared PRIVATE MPI::MPI_CXX)

add_executable(compress_analysis metrics.cc svd.cc analysis.cc qentropy.cc)
target_compile_features(compress_analysis PRIVATE cxx_std_20)
target_link_libraries(compress_analysis PRIVATE LibPressioTools::libpressio_meta Eigen3::Eigen OpenMP::OpenMP_CXX LibDistributed::libdistributed)
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  target_compile_definitions(compress_analysis PRIVATE DEBUG)
endif()

install(TARGETS compress_analysis)
