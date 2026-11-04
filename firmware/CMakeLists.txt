# The following lines of boilerplate have to be in your project's CMakeLists
# in this exact order for cmake to work correctly
cmake_minimum_required(VERSION 3.22)

# Board overrides and private credentials (Wi-Fi + Thread network) are layered
# on top of the example defaults. Later files win.
set(SECRETS_FILE "${CMAKE_CURRENT_LIST_DIR}/../sdkconfig.secrets")
if(NOT EXISTS "${SECRETS_FILE}")
    message(FATAL_ERROR "Missing ${SECRETS_FILE}. Copy sdkconfig.secrets.example "
                        "to sdkconfig.secrets in the repo root and fill it in.")
endif()
set(SDKCONFIG_DEFAULTS "sdkconfig.defaults;sdkconfig.defaults.xiao;${SECRETS_FILE}")

include($ENV{IDF_PATH}/tools/cmake/project.cmake)
# "Trim" the build. Include the minimal set of components, main, and anything it depends on.
idf_build_set_property(MINIMAL_BUILD ON)
project(esp_ot_br)
