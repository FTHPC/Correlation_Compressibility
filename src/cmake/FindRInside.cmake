if(DEFINED ENV{SPACK_CC})
  message(WARNING "unsetting R_HOME when building with spack")
  unset(ENV{R_HOME})
endif()

find_program(R_CMD
  R
  HINTS ENV R_HOME
  PATH_SUFFIXES /bin/
  )


execute_process(
  COMMAND ${R_CMD} CMD config --cppflags
  OUTPUT_VARIABLE R_CPPFLAGS
  OUTPUT_STRIP_TRAILING_WHITESPACE
  )
execute_process(
  COMMAND ${R_CMD} CMD config CXXFLAGS
  OUTPUT_VARIABLE R_CXXFLAGS
  OUTPUT_STRIP_TRAILING_WHITESPACE
  )
execute_process(
  COMMAND ${R_CMD} CMD config --ldflags
  OUTPUT_VARIABLE R_LDFLAGS
  OUTPUT_STRIP_TRAILING_WHITESPACE
  )
execute_process(
  COMMAND ${R_CMD} CMD config BLAS_LIBS
  OUTPUT_VARIABLE R_BLASLIBS
  OUTPUT_STRIP_TRAILING_WHITESPACE
  )
execute_process(
  COMMAND ${R_CMD} CMD config LAPACK_LIBS
  OUTPUT_VARIABLE R_LAPACKLIBS
  OUTPUT_STRIP_TRAILING_WHITESPACE
  )
execute_process(
  COMMAND ${R_CMD} --vanilla --slave
  OUTPUT_VARIABLE RCPP_CXXFLAGS
  INPUT_FILE "${CMAKE_CURRENT_SOURCE_DIR}/cmake/rcpp_cxxflags.in"
  )
execute_process(
  COMMAND ${R_CMD} --vanilla --slave
  OUTPUT_VARIABLE RCPP_LDFLAGS
  INPUT_FILE "${CMAKE_CURRENT_SOURCE_DIR}/cmake/rcpp_ldflags.in"
  OUTPUT_STRIP_TRAILING_WHITESPACE
  )
execute_process(
  COMMAND ${R_CMD} --vanilla --slave
  OUTPUT_VARIABLE RINSIDE_CXXFLAGS
  INPUT_FILE "${CMAKE_CURRENT_SOURCE_DIR}/cmake/rinside_cxxflags.in"
  OUTPUT_STRIP_TRAILING_WHITESPACE
  )
execute_process(
  COMMAND ${R_CMD} --vanilla --slave
  OUTPUT_VARIABLE RINSIDE_LDFLAGS
  INPUT_FILE "${CMAKE_CURRENT_SOURCE_DIR}/cmake/rinside_ldflags.in"
  OUTPUT_STRIP_TRAILING_WHITESPACE
  )
execute_process(
  COMMAND ${R_CMD} --vanilla --slave
  OUTPUT_VARIABLE RINSIDE_VERSION
  INPUT_FILE "${CMAKE_CURRENT_SOURCE_DIR}/cmake/rinside_version.in"
  OUTPUT_STRIP_TRAILING_WHITESPACE
  )

message(DEBUG " RCpp:::CxxFlags ${RCPP_CXXFLAGS}")
message(DEBUG " RInside:::CxxFlags ${RINSIDE_CXXFLAGS}")
message(DEBUG " R:::CppFlags ${R_CPPFLAGS}")
message(DEBUG " R_BLASLIBS ${R_BLASLIBS}")
message(DEBUG " R_LAPACKLIBS  ${R_LAPACKLIBS}")
message(DEBUG " R_LDFLAGS ${R_LDFLAGS}")
message(DEBUG " RINSIDE_LDFLAGS ${RINSIDE_LDFLAGS}")
message(DEBUG " RCPP_LDFLAGS ${RCPP_LDFLAGS}")
message(DEBUG " RCPP_CXXFLAGS_SEP ${RCPP_CXXFLAGS_SEP}")
message(DEBUG " RINSIDE_CXXFLAGS_SEP ${RINSIDE_CXXFLAGS_SEP}")
separate_arguments(RCPP_CXXFLAGS_SEP UNIX_COMMAND "${RCPP_CXXFLAGS}")
separate_arguments(RINSIDE_CXXFLAGS_SEP UNIX_COMMAND "${RINSIDE_CXXFLAGS}")


if(NOT TARGET RInside::RInside)
  add_library(RInside::RInside INTERFACE IMPORTED)
  target_compile_options(RInside::RInside
    INTERFACE
    "${RCPP_CXXFLAGS_SEP}"
    "${RINSIDE_CXXFLAGS_SEP}"
    "${R_CPPFLAGS}"
    "${RCPP_CXXFLAGS_SEP}"
    )
  target_link_libraries(RInside::RInside
    INTERFACE
    ${R_BLASLIBS}
    ${R_LAPACKLIBS}
    ${R_LDFLAGS}
    ${RINSIDE_LDFLAGS}
    ${RCPP_LDFLAGS}
    )
endif()
