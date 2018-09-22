#!/bin/bash

project_name=$1
dir=$(pwd)
proj_root=${dir}/${project_name}

src_dir=src
tests_dir=tests
app_dir=app
benchmark_dir=benchmark
build_dir=build
template_dir=template

cmake_version=3.0
boost_path="~/Downloads/boost_1_68_0"
openssl_path=""
gtest_path="~/Workspace/googletest/googletest"
gmock_path="~/Workspace/googletest/googlemock"

#Chose between one of the two Test Frameworks. 
#If you choose Boost Test, you must set use_boost=y
use_google_test=y
use_boost_test=n

use_boost=y
use_openssl=n

####################################################################################
# Create Directory Tree
####################################################################################
create_dir_tree () {
  if [ ! -d "$proj_root" ]; then
    mkdir ${proj_root}
    mkdir ${proj_root}/${src_dir}
    mkdir ${proj_root}/${tests_dir}
    mkdir ${proj_root}/${app_dir}
    mkdir ${proj_root}/${benchmark_dir}
    mkdir ${proj_root}/${build_dir}
    #Generate template directories
    mkdir ${proj_root}/${src_dir}/${template_dir}
    mkdir ${proj_root}/${tests_dir}/${template_dir}
    mkdir ${proj_root}/${app_dir}/${template_dir}
    mkdir ${proj_root}/${benchmark_dir}/${template_dir}
    mkdir ${proj_root}/${build_dir}/${template_dir}
  fi
}
####################################################################################
# PROJECT ROOT - CMakeLists.txt 
####################################################################################
root_project_cmake () {
echo "Generate CMake at ${proj_root}"
cat << ROOT_CMAKE  >> ${proj_root}/CMakeLists.txt
cmake_minimum_required(VERSION ${cmake_version})
project(${project_name} C CXX)

enable_testing()

if("\${CMAKE_CXX_COMPILER_ID}" MATCHES "(GNU|Clang)")
    set(CMAKE_CXX_FLAGS "-std=c++14")
endif()

include_directories(src)

ROOT_CMAKE

if [ $use_boost = y ] 
then 
boost_lib
fi

if [ $use_openssl = y ] 
then
openssl_lib
fi

cat << ROOT_CMAKE_DIRS  >> ${proj_root}/CMakeLists.txt

add_subdirectory(${src_dir})
add_subdirectory(${tests_dir})
add_subdirectory(${app_dir})
add_subdirectory(${benchmark_dir})

ROOT_CMAKE_DIRS
}

boost_lib () {

cat << BOOSTLIB_GEN  >> ${proj_root}/CMakeLists.txt
set(BOOST_ROOT ${boost_pth})
# Locate Boost libraries: unit_test_framework, date_time and regex
set(Boost_USE_STATIC_LIBS ON)
set(Boost_USE_MULTITHREADED ON)
set(Boost_USE_STATIC_RUNTIME OFF)
find_package(Boost 1.59 REQUIRED COMPONENTS unit_test_framework date_time regex)

include_directories(Boost_INCLUDE_DIRS)

BOOSTLIB_GEN

}

openssl_lib () {
cat << OPENSSL_GEN  >> ${proj_root}/CMakeLists.txt
set(OPENSSL_ROOT_DIR ${openssl_path})
# Locate OpenSSL libraries
#REad Only variables
#OPENSSL_FOUND - system has the OpenSSL library
#OPENSSL_INCLUDE_DIR - the OpenSSL include directory
#OPENSSL_LIBRARIES - The libraries needed to use OpenSSL
#OPENSSL_VERSION - This is set to $major.$minor.$revision$path (eg. 0.9.8s)

set(OPENSSL_USE_STATIC_LIBS TRUE)
find_package(OpenSSL REQUIRED)
OPENSSL_GEN
}
####################################################################################
# tests Directory - CMakeLists.txt 
####################################################################################
tests_cmake () {
echo "Generate tests CMake"
cat << TEST_GEN  >> ${proj_root}/${test_dir}/CMakeLists.txt
cmake_minimum_required(VERSION ${cmake_version})
project(${project_name}_test C CXX)

TEST_GEN

if [ $use_google_test = y ] 
then
google_test
fi

cat << TEST_GEN  >> ${proj_root}/${test_dir}/CMakeLists.txt

add_subdirectory(${template_dir})

TEST_GEN

test_template

}

google_test () {
cat << GOOGLETEST_GEN  >> ${proj_root}/${test_dir}/CMakeLists.txt
set(GMOCK_DIR ${gmock_path}
    CACHE PATH "The path to the GoogleMock test framework.")

set(GTEST_DIR ${gtest_path}
    CACHE PATH "The path to the GoogleTest test framework.")

set(BUILD_TESTING ON)
enable_testing()

if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
  # force this option to ON so that Google Test will use /MD instead of /MT
  # /MD is now the default for Visual Studio, so it should be our default, too
  option(gtest_force_shared_crt
  "Use shared (DLL) run-time lib even when Google Test is built as static lib."
  ON)
elseif (APPLE)
  add_definitions(-DGTEST_USE_OWN_TR1_TUPLE=1)
endif()

add_subdirectory(\${GMOCK_DIR} ${CMAKE_BINARY_DIR}/gmock)

include_directories(\${GMOCK_DIR}/gtest/include \${GMOCK_DIR}/include)
include_directories(\${GTEST_DIR}/gtest/include \${GTEST_DIR}/include)
GOOGLETEST_GEN
}
####################################################################################
# tests/template Directory - CMakeLists.txt 
####################################################################################
test_template() {

echo "Generate test template"

link_libraries=projlib

if [ use_google_test = y ]
then
cat << TEST_TEMPLATE_GEN  >> ${proj_root}/${test_dir}/${template_dir}/CMakeLists.txt

add_executable(test_gtest_template template_gtest.cpp)
target_link_libraries(test_gtest_temaplte ${link_libraries} gmock_main)
add_test(test_gtest_template test_gtest_template)
TEST_TEMPLATE_GEN
fi #end if [ use_google_test = y ]

if [ use_boost = y ]
then
cat << TEST_TEMPLATE_GEN  >> ${proj_root}/${test_dir}/${template_dir}/CMakeLists.txt

add_executable(test_boosttest_template template_boosttest_.cpp)
target_link_libraries(test_boosttest__temaplte ${link_libraries} \${Boost_LIBRARIES})
add_test(test_boosttest_template test_boosttest_template)
TEST_TEMPLATE_GEN
fi #end if [ use_google_test = n && use_boost = y ]

if [[ use_google_test = n ] && [ use_boost = n ]]
then
cat << TEST_TEMPLATE_GEN  >> ${proj_root}/${test_dir}/${template_dir}/CMakeLists.txt

add_executable(test_nolib_template test_nolib_template.cpp)
target_link_libraries(test_nolib_template ${link_libraries})
add_test(test_nolib_template test_nolib_template)
TEST_TEMPLATE_GEN
fi #end if [ use_google_test = n && use_boost = n ]

test_cpp_template
}

test_cpp_template () {
  echo "Generate cpp tests templates"
}

####################################################################################
# SRC Directory - CMakeLists.txt 
####################################################################################
src_cmake () {
  echo "Generate src CMakeLists.txt"
}

src_template () {
echo "Generate src template"
}

####################################################################################
# app Directory - CMakeLists.txt 
####################################################################################
app_cmake () {
echo "Generate app CMake"
}

app_template () {
echo "Generate app template"
}

####################################################################################
# main
####################################################################################
main () {
  create_dir_tree
  root_project_cmake
  tests_cmake
}

main











