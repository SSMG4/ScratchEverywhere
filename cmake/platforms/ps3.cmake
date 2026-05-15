set(SE_DEFAULT_OUTPUT_NAME "scratch-ps3")

set(SE_RENDERER_VALID_OPTIONS "sdl2")
set(SE_AUDIO_ENGINE_VALID_OPTIONS "sdl2")
set(SE_DEPS_VALID_OPTIONS "fallback" "system")

set(SE_CACHING_DEFAULT OFF)
set(SE_CMAKERC_DEFAULT ON)

set(SE_ALLOW_CMAKERC ON)
set(SE_ALLOW_CLOUDVARS OFF)
set(SE_ALLOW_DOWNLOAD OFF)

set(SE_HAS_THREADS ON)

set(SE_HAS_TOUCH FALSE)
set(SE_HAS_MOUSE FALSE)
set(SE_HAS_KEYBOARD FALSE)
set(SE_HAS_CONTROLLER TRUE)

set(SE_PLATFORM_DEFINITIONS "PS3" "__PS3__" "__PSL1GHT__")
set(SE_PLATFORM "ps3")

macro(package_platform)
    add_ps3_fself(scratch-everywhere)
    add_ps3_pkg(
        scratch-everywhere
        "${SE_APP_TITLEID}"
        "${SE_APP_NAME}"
        "${SE_APP_VERSION}"
    )
endmacro()
