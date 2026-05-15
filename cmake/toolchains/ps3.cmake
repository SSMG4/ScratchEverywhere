cmake_minimum_required(VERSION 3.5)

if(NOT DEFINED ENV{PS3DEV})
    set(PS3DEV /opt/ps3dev)
    set(ENV{PS3DEV} ${PS3DEV})
else()
    set(PS3DEV $ENV{PS3DEV})
endif()

if(NOT DEFINED ENV{PSL1GHT})
    set(PSL1GHT ${PS3DEV})
    set(ENV{PSL1GHT} ${PSL1GHT})
else()
    set(PSL1GHT $ENV{PSL1GHT})
endif()

set(PS3 TRUE)

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR powerpc64)
set(CMAKE_CROSSCOMPILING TRUE)
set(CMAKE_SYSTEM_VERSION 1)

set(TOOLCHAIN_BIN "${PS3DEV}/ppu/bin")
set(TOOLCHAIN_PREFIX "${TOOLCHAIN_BIN}/powerpc64-unknown-elf")

set(CMAKE_C_COMPILER   "${TOOLCHAIN_PREFIX}-gcc"   CACHE PATH "")
set(CMAKE_CXX_COMPILER "${TOOLCHAIN_PREFIX}-g++"   CACHE PATH "")
set(CMAKE_AR           "${TOOLCHAIN_PREFIX}-ar"     CACHE PATH "")
set(CMAKE_RANLIB       "${TOOLCHAIN_PREFIX}-ranlib" CACHE PATH "")
set(CMAKE_STRIP        "${TOOLCHAIN_PREFIX}-strip"  CACHE PATH "")

set(CMAKE_FIND_ROOT_PATH "${PS3DEV}/ppu" "${PSL1GHT}/ppu")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

set(BUILD_SHARED_LIBS OFF CACHE INTERNAL "Shared libs not available")

set(PS3_ARCH_FLAGS "-mcpu=powerpc64 -m64 -mhard-float -mbig-endian")

set(CMAKE_C_FLAGS_INIT
    "${PS3_ARCH_FLAGS} \
     -D__PS3__ -D__PSL1GHT__ -DPS3 \
     -I${PSL1GHT}/ppu/include \
     -I${PS3DEV}/ppu/powerpc64-unknown-elf/include"
)
set(CMAKE_CXX_FLAGS_INIT "${CMAKE_C_FLAGS_INIT}")

set(CMAKE_EXE_LINKER_FLAGS_INIT
    "-L${PSL1GHT}/ppu/lib \
     -L${PS3DEV}/ppu/powerpc64-unknown-elf/lib \
     -Wl,--gc-sections"
)

set(CMAKE_C_STANDARD_LIBRARIES   "-llv2 -lm -lc")
set(CMAKE_CXX_STANDARD_LIBRARIES "-llv2 -lm -lc")

set(CMAKE_FIND_PACKAGE_PREFER_CONFIG TRUE)

set(ENV{PKG_CONFIG_LIBDIR} "${PSL1GHT}/ppu/lib/pkgconfig:${PS3DEV}/ppu/lib/pkgconfig")
set(ENV{PKG_CONFIG_PATH} "")

function(__ps3_target_derive_name outvar target suffix)
    get_target_property(dir ${target} BINARY_DIR)
    get_target_property(outname ${target} OUTPUT_NAME)
    if(NOT outname)
        set(outname "${target}")
    endif()
    set(${outvar} "${dir}/${outname}${suffix}" PARENT_SCOPE)
endfunction()

function(add_ps3_fself target)
    __ps3_target_derive_name(FSELF_OUTPUT ${target} ".self")

    add_custom_command(
        OUTPUT "${FSELF_OUTPUT}"
        COMMAND "${PSL1GHT}/host/bin/fself"
                "$<TARGET_FILE:${target}>"
                "${FSELF_OUTPUT}"
        VERBATIM
        DEPENDS "${target}"
    )
    add_custom_target("${target}_fself" ALL DEPENDS "${FSELF_OUTPUT}")
endfunction()

function(add_ps3_pkg target title_id content_title content_version)
    __ps3_target_derive_name(FSELF_OUTPUT ${target} ".self")
    __ps3_target_derive_name(PKG_OUTPUT   ${target} ".pkg")
    get_target_property(BINARY_DIR ${target} BINARY_DIR)
    get_target_property(outname    ${target} OUTPUT_NAME)
    if(NOT outname)
        set(outname "${target}")
    endif()

    set(PKG_STAGE_DIR "${BINARY_DIR}/${outname}-pkgstage")
    set(SFO_GEN_XML   "${BINARY_DIR}/${outname}-sfo.xml")

    string(REGEX MATCH "([0-9]+\\.[0-9]+)" _ver_clean "${content_version}")
    if("${_ver_clean}" STREQUAL "")
        set(_ver_clean "01.00")
    endif()

    set(SE_APP_NAME     "${content_title}")
    set(SE_APP_TITLEID  "${title_id}")
    set(SE_APP_VER_PAD  "${_ver_clean}")

    set(CONTENT_ID "UP0001-${title_id}_00-0000000000000001")

    configure_file(
        "${CMAKE_CURRENT_SOURCE_DIR}/gfx/ps3/sfo.xml.in"
        "${SFO_GEN_XML}"
        @ONLY
    )

    add_custom_command(
        OUTPUT "${PKG_OUTPUT}"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${PKG_STAGE_DIR}/USRDIR"
        COMMAND "${PSL1GHT}/host/bin/sfo"
                "-f" "${SFO_GEN_XML}"
                "${PKG_STAGE_DIR}/PARAM.SFO"
        COMMAND ${CMAKE_COMMAND} -E copy
                "${FSELF_OUTPUT}"
                "${PKG_STAGE_DIR}/USRDIR/EBOOT.BIN"
        COMMAND ${CMAKE_COMMAND} -E copy
                "${CMAKE_CURRENT_SOURCE_DIR}/gfx/ps3/ICON0.png"
                "${PKG_STAGE_DIR}/ICON0.PNG"
        COMMAND "${PSL1GHT}/host/bin/pkg"
                "--contentid" "${CONTENT_ID}"
                "${PKG_STAGE_DIR}/"
                "${PKG_OUTPUT}"
        VERBATIM
        DEPENDS "${target}_fself"
    )
    add_custom_target("${target}_pkg" ALL DEPENDS "${PKG_OUTPUT}")
endfunction()
