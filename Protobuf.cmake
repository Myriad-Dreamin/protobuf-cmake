
function(protobuf_internal_customized_generate_cpp target SRCS HDRS)
    cmake_parse_arguments(proto_args "" "PROTO_ROOT" "" "${ARGN}")
    set(_protobuf_root ${proto_args_PROTO_ROOT})
    set(_protobuf_sources ${proto_args_UNPARSED_ARGUMENTS})

    if (NOT _protobuf_root)
        set(_protobuf_root .)
    endif ()

    # calc sources, headers
    set(${SRCS} ${_protobuf_sources})
    set(${HDRS} ${_protobuf_sources})
    list(TRANSFORM ${SRCS} PREPEND ${CMAKE_CURRENT_BINARY_DIR}/)
    list(TRANSFORM ${HDRS} PREPEND ${CMAKE_CURRENT_BINARY_DIR}/)
    list(JOIN ${SRCS} ";" "${SRCS}")
    list(JOIN ${HDRS} ";" "${HDRS}")
    string(REGEX REPLACE "[.]proto([;]|$)" ".pb.cc;" ${SRCS} "${${SRCS}}")
    string(REGEX REPLACE "[.]proto([;]|$)" ".pb.h;" ${HDRS} "${${HDRS}}")
    set(${SRCS} ${${SRCS}} PARENT_SCOPE)
    set(${HDRS} ${${HDRS}} PARENT_SCOPE)

    # calc absolute inclusion
    get_filename_component(_abs_protobuf_root ${CMAKE_CURRENT_SOURCE_DIR}/${_protobuf_root}/ ABSOLUTE)
    set(_abs_protobuf_sources)
    foreach(src ${_protobuf_sources})
        list(TRANSFORM src PREPEND ${_abs_protobuf_root}/)
        get_filename_component(_abs_protobuf_sources ${src} ABSOLUTE)
        list(APPEND _abs_protobuf_sources ${_protobuf_sources})
    endforeach()

    # calc protobuf inclusion
    # note: the output variable proto_inclusion_flags is in the form of
    # ```python
    # proto_inclusion_flags = [f'-I{dep}' for dep in target.PROTOBUF_SOURCE_DIRECTORIES]
    # proto_inclusion_flags = " ".join(proto_inclusion_flags)
    # ```
    set(proto_inclusion_flags "$<TARGET_PROPERTY:${target},PROTOBUF_SOURCE_DIRECTORIES>")
    set(proto_inclusion_flags "$<$<BOOL:${proto_inclusion_flags}>:-I$<JOIN:${proto_inclusion_flags},;-I>>")

    add_custom_command(
            OUTPUT ${${SRCS}} ${${HDRS}}
            COMMAND protobuf::protoc --cpp_out ${CMAKE_CURRENT_BINARY_DIR} "${proto_inclusion_flags}" ${_protobuf_sources}
            COMMAND_EXPAND_LISTS
            DEPENDS ${_abs_protobuf_sources} protobuf::protoc
            COMMENT "Running cpp protocol buffer compiler on ${_abs_protobuf_sources}"
            WORKING_DIRECTORY ${_abs_protobuf_root}
            VERBATIM)
endfunction()

macro(_target_update_protobuf_lib_properties target prop linkage)
    get_target_property(proto_props ${target} ${prop})
    if(NOT proto_props)
        set(proto_props)
    endif()
    list(APPEND proto_props ${ARGN})
    list(REMOVE_DUPLICATES proto_props)

    set_target_properties(${target} PROPERTIES ${prop} "${proto_props}")
endmacro()

macro(_target_extend_protobuf_lib_properties target prop linkage)
    get_target_property(proto_props ${target} ${prop})
    if(NOT proto_props)
        set(proto_props)
    endif()
    foreach(proto_dep ${ARGN})
        get_target_property(dep_proto_props ${proto_dep} ${prop})
        if(NOT dep_proto_props)
            set(dep_proto_props)
        endif()
        list(APPEND proto_props ${dep_proto_props})
    endforeach()
    list(REMOVE_DUPLICATES proto_props)

    set_target_properties(${target} PROPERTIES ${prop} "${proto_props}")
endmacro()

macro(_target_adjust_protobuf_source_inclusion target linkage)
    get_target_property(protobuf_dependencies ${target} PROTOBUF_DEPENDENT_LIBRARIES)
    if (NOT (NOT protobuf_dependencies))
        foreach(proto_lower ${protobuf_dependencies})
            target_include_protobuf_directories(${proto_lower} ${linkage} ${ARGN})
        endforeach()
    endif()
endmacro()

macro(target_include_protobuf_directories target linkage)
    _target_update_protobuf_lib_properties(${target} PROTOBUF_SOURCE_DIRECTORIES ${linkage} ${ARGN})
    _target_adjust_protobuf_source_inclusion(${target} ${linkage} ${ARGN})
endmacro()

macro(target_link_protobuf_libraries target linkage)
    _target_extend_protobuf_lib_properties(${target} PROTOBUF_SOURCE_DIRECTORIES ${linkage} ${ARGN})
    foreach(proto_upper ${ARGN})
        if (${proto_upper} STREQUAL ${target})
            message(FATAL_ERROR "target_link_protobuf_libraries: a circular dependency found on ${target}")
        endif()

        _target_update_protobuf_lib_properties(${proto_upper} PROTOBUF_DEPENDENT_LIBRARIES ${linkage} ${target})
        get_target_property(protobuf_dependent ${proto_upper} PROTOBUF_DEPENDENT_LIBRARIES)
    endforeach()
    _target_adjust_protobuf_source_inclusion(${target} ${linkage} ${ARGN})
    target_link_libraries(${target} ${linkage} ${ARGN})
endmacro()

macro(add_protobuf_library target)
    add_library(${target})
    set_target_properties(${target} PROPERTIES PROTOBUF_SOURCE_DIRECTORIES "${CMAKE_CURRENT_SOURCE_DIR}")
    kfuzz_generate_protobuf_cpp(${target} PROTO_GENERATED_SRCS PROTO_GENERATED_HDRS ${ARGN})
    target_sources(${target} PRIVATE ${PROTO_GENERATED_SRCS} ${PROTO_GENERATED_HDRS})
endmacro()
