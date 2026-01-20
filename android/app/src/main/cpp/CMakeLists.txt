# For more information about using CMake with Android Studio, read the
# documentation: https://d.android.com/studio/projects/add-native-code.html

# Sets the minimum version of CMake required to build the native library.

cmake_minimum_required(VERSION 3.4.1)

# Creates and names a library, sets it as either STATIC or SHARED, and provides
# the relative paths to its source code. You can define multiple libraries, and
# CMake builds them for you. Gradle automatically packages shared libraries with
# your APK.

set(PaddleLite_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../../")
include_directories(${PaddleLite_DIR}/cxx/include)
set(PaddleLite_LIB_DIR
        "${CMAKE_CURRENT_SOURCE_DIR}/../../../../paddle_lite/inference_lite_lib.android.armv8.gcc.c++_shared.with_cv/cxx/lib")

set(OpenCV_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../../sdk/native/jni")
message(STATUS "opencv dir: ${OpenCV_DIR}")
find_package(OpenCV REQUIRED)
message(STATUS "OpenCV libraries: ${OpenCV_LIBS}")
include_directories(${OpenCV_INCLUDE_DIRS})

find_package(OpenMP REQUIRED)
if (OPENMP_FOUND)
    message(STATUS "OpenMP found")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS} -fopenmp")
endif ()
aux_source_directory(. SOURCES)
set(CMAKE_CXX_FLAGS
        "${CMAKE_CXX_FLAGS} -ffast-math -Ofast -Os"
        )
set(CMAKE_CXX_FLAGS
        "${CMAKE_CXX_FLAGS} -fvisibility=hidden -fvisibility-inlines-hidden -fdata-sections -ffunction-sections"
        )
set(CMAKE_SHARED_LINKER_FLAGS
        "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--gc-sections -Wl,-z,nocopyreloc")

add_library(
        # Sets the name of the library.
        Native
        # Sets the library as a shared library.
        SHARED
        # Provides a relative path to your source file(s).
        ${SOURCES})

find_library(
        # Sets the name of the path variable.
        log-lib
        # Specifies the name of the NDK library that you want CMake to locate.
        log)

add_library(
        paddle_api_light_bundled
        STATIC
        IMPORTED)

set_target_properties(
        paddle_api_light_bundled
        PROPERTIES
        IMPORTED_LOCATION
        ${PaddleLite_LIB_DIR}/libpaddle_api_light_bundled.a)


# Specifies libraries CMake should link to your target library. You can link
# multiple libraries, such as libraries you define in this build script,
# prebuilt third-party libraries, or system libraries.

target_link_libraries(
        # Specifies the target library.
        Native
        paddle_api_light_bundled
        ${OpenCV_LIBS}
        OpenMP::OpenMP_CXX
        GLESv2
        EGL
        jnigraphics
        ${log-lib}
)

add_custom_command(
        TARGET Native
        POST_BUILD
        COMMAND
        ${CMAKE_COMMAND} -E copy
        ${OpenCV_DIR}/../libs/${ANDROID_ABI}/libopencv_java4.so
        ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/libopencv_java4.so)
