#

# TODO JULIA_CPU_TARGET
set(JULIA_CPU_TARGET native)

jl_custom_target(julia-inference0
  "inference0.o;inference0.ji"
  coreimg.jl julia-ui "${build_private_libdir}/inference0.fnames"
  COMMAND "${build_bindir}/julia" -C ${JULIA_CPU_TARGET}
  --build "${CMAKE_CURRENT_BINARY_DIR}/inference0" -f coreimg.jl
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")

if(NOT EXISTS "${CMAKE_CURRENT_BINARY_DIR}/dummy.c")
  execute_process(COMMAND "${CMAKE_COMMAND}" -E
    touch "${CMAKE_CURRENT_BINARY_DIR}/dummy.c")
endif()

add_library(julia-inference0-so MODULE "${CMAKE_CURRENT_BINARY_DIR}/dummy.c")

target_link_libraries(julia-inference0-so
  "${CMAKE_CURRENT_BINARY_DIR}/inference0.o"
  libjulia)

set_target_properties(julia-inference0-so PROPERTIES
  OUTPUT_NAME inference0
  PREFIX "")

add_dependencies(julia-inference0-so julia-inference0)

# TODO? use inference.so if it exists
jl_custom_target(julia-inference
  "${build_private_libdir}/inference.o;${build_private_libdir}/inference.ji"
  "coreimg.jl;${CMAKE_CURRENT_BINARY_DIR}/inference0.o"
  "julia-ui;julia-inference0-so"
  inference0.fnames
  COMMAND "${build_bindir}/julia" -C ${JULIA_CPU_TARGET}
  --build "${build_private_libdir}/inference" -f
  -J "${CMAKE_CURRENT_BINARY_DIR}/inference0.ji" coreimg.jl
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")

add_library(julia-inference-so MODULE "${CMAKE_CURRENT_BINARY_DIR}/dummy.c")

target_link_libraries(julia-inference-so
  "${build_private_libdir}/inference.o"
  libjulia)

set_target_properties(julia-inference-so PROPERTIES
  OUTPUT_NAME inference
  PREFIX ""
  LIBRARY_OUTPUT_DIRECTORY "${build_private_libdir}")

add_dependencies(julia-inference-so julia-inference)

# TODO find perl
set(PERL_COMMAND perl)

string(REPLACE ";" " " PERL_COMMAND_STR "${PERL_COMMAND}")
string(REPLACE ";" " " CPP_COMMAND_STR "${CPP_COMMAND}")
configure_file(errno_h.jl.sh.in errno_h.jl.sh @ONLY)

add_custom_command(OUTPUT errno_h.jl
  COMMAND sh errno_h.jl.sh errno_h.jl
  WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
  DEPENDS errno_h.jl.sh.in)

add_custom_target(julia-errno_h.jl
  DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/errno_h.jl")
