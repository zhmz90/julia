#

include(CMakeVarMacros)

get_filename_component(jl_cmake_utils_dir
  "${CMAKE_CURRENT_LIST_FILE}" PATH)

set(jl_cmake_utils_dir "${jl_cmake_utils_dir}" CACHE "" INTERNAL FORCE)

function(jl_std_fpath var path)
  if(NOT IS_ABSOLUTE "${path}")
    set(${var} "${path}" PARENT_SCOPE)
    return()
  endif()
  file(RELATIVE_PATH src_path "${CMAKE_CURRENT_SOURCE_DIR}" "${path}")
  file(RELATIVE_PATH bin_path "${CMAKE_CURRENT_BINARY_DIR}" "${path}")
  string(LENGTH "${src_path}" src_len)
  string(LENGTH "${bin_path}" bin_len)
  if(src_len GREATER bin_len)
    set(${var} "${bin_path}" PARENT_SCOPE)
  else()
    set(${var} "${src_path}" PARENT_SCOPE)
  endif()
endfunction()

function(jl_fpath_to_target var file)
  jl_std_fpath(std_fname "${file}")
  string(REGEX REPLACE "[^-_.a-zA-Z0-9]" "_" std_fname "${std_fname}")
  string(REGEX REPLACE "_+" "_" std_fname "${std_fname}")
  cmake_utils_get_unique_name("${std_fname}" target)
  set("${var}" "${target}" PARENT_SCOPE)
endfunction()

function(jl_rewrite_dep_list var deps)
  set(new_deps)
  foreach(dep ${deps})
    if(TARGET "${dep}")
      set(new_deps ${new_deps} "$<TARGET_FILE:${dep}>")
    elseif(IS_ABSOLUTE "${dep}")
      set(new_deps ${new_deps} ${dep})
    else()
      get_filename_component(dep "${dep}" ABSOLUTE)
      set(new_deps ${new_deps} ${dep})
    endif()
  endforeach()
  set(${var} "${new_deps}" PARENT_SCOPE)
endfunction()

function(jl_rewrite_output_list var outputs)
  set(new_outputs)
  foreach(output ${outputs})
    if(IS_ABSOLUTE "${output}")
      set(new_outputs ${new_outputs} ${output})
    else()
      set(new_outputs ${new_outputs} "${CMAKE_CURRENT_BINARY_DIR}/${output}")
    endif()
  endforeach()
  set(${var} "${new_outputs}" PARENT_SCOPE)
endfunction()

function(jl_custom_target target outputs output_deps target_deps autodep_file)
  jl_rewrite_dep_list(output_deps "${output_deps}")
  jl_rewrite_output_list(outputs "${outputs}")
  if((NOT "${autodep_file}" STREQUAL "") AND
      (NOT IS_ABSOLUTE "${autodep_file}"))
    set(autodep_file "${CMAKE_CURRENT_BINARY_DIR}/${autodep_file}")
  endif()
  add_custom_target("${target}" ALL
    COMMAND "${CMAKE_COMMAND}"
    "-DOUTPUTS=${outputs}" "-DOUTPUT_DEPS=${output_deps}"
    "-DAUTODEP_FILE=${autodep_file}" "-DCOMMAND_SPEC=${ARGN}"
    "-DCUR_BIN_DIR=${CMAKE_CURRENT_BINARY_DIR}"
    "-DCUR_SRC_DIR=${CMAKE_CURRENT_SOURCE_DIR}"
    -P "${jl_cmake_utils_dir}/jl_custom_target.cmake"
    DEPENDS ${target_deps} VERBATIM)
endfunction()

function(jl_custom_output outputs output_deps target_deps autodep_file)
  if(NOT outputs)
    cmake_utils_get_unique_name(jl_custom_target target)
  else()
    list(GET outputs 0 output1)
    jl_fpath_to_target(target "${output1}")
  endif()
  set(jl_custom_output_target "${target}" PARENT_SCOPE)
  jl_custom_target("${target}" "${outputs}" "${output_deps}"
    "${target_deps}" "${autodep_file}" ${ARGN})
endfunction()

# add_custom_command(OUTPUT "${build_private_libdir}/inference0.o"
#   "${build_private_libdir}/inference0.ji"
#   COMMAND "${build_bindir}/julia" -C ${JULIA_CPU_TARGET}
#   --build "${build_private_libdir}/inference0" -f coreimg.jl
#   WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
#   DEPENDS ${core_img_SRCS})

# add_custom_target(julia-inference0
#   DEPENDS "${build_private_libdir}/inference0.o"
#   julia-ui)

# function(jl_sysimg_target outputs target output_deps target_deps autodep_file)
#   set(gen_script "${CMAKE_CURRENT_BINARY_DIR}/.jl_gen_sysimg-${target}.sh")
#   set(stamp_file "${CMAKE_CURRENT_BINARY_DIR}/.jl_gen_sysimg-${target}.stamp")
#   configure_file(jl_gen_sysimg.sh.in "${gen_script}" @ONLY)
#   # Force a recompilation if direct
#   add_custom_command(OUTPUT "${stamp_file}"
#     COMMAND "${CMAKE_COMMAND}" -E touch "${stamp_file}"
#     DEPENDS ${output_deps})
# endfunction()
