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
boost_version=1.59
boost_path="/home/filipe/Downloads/boost_1_68_0"
openssl_path=""
gtest_path="/home/filipe/Documents/Workspace/googletest/googletest"
gmock_path="/home/filipe/Documents/Workspace/googletest/googlemock"

use_boost=y
use_openssl=y

#Chose between one of the two Test Frameworks. 
#If you choose Boost Test, you must set use_boost=y
use_google_test=y
use_boost_test=n

external_libs=""

verifications () {

if [[ $use_boost_test = y ]] && [[ $use_boost = n ]]; then
  echo "If you want to use BOOST TEST framework, you must select use_boost=y in this script."
  exit
fi

}

generate_external_libs() {
if [ $use_boost = y ]; then 
external_libs+="\${Boost_LIBRARIES} "
fi

if [ $use_openssl = y ]; then 
external_libs+="\${OPENSSL_LIBRARIES} "
fi
}
####################################################################################
# Create Directory Tree
####################################################################################
link_libraries=module

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
set(BOOST_ROOT ${boost_path})
# Locate Boost libraries: unit_test_framework, date_time and regex
set(Boost_USE_STATIC_LIBS ON)
set(Boost_USE_MULTITHREADED ON)
set(Boost_USE_STATIC_RUNTIME OFF)
find_package(Boost ${boost_version} REQUIRED COMPONENTS unit_test_framework date_time regex)

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
cat << TEST_GEN  >> ${proj_root}/${tests_dir}/CMakeLists.txt
cmake_minimum_required(VERSION ${cmake_version})
project(${project_name}_test C CXX)

TEST_GEN

if [ $use_google_test = y ]; then
google_test
fi

cat << TEST_GEN  >> ${proj_root}/${tests_dir}/CMakeLists.txt

add_subdirectory(${template_dir})

TEST_GEN

test_template
}

google_test () {
cat << GOOGLETEST_GEN  >> ${proj_root}/${tests_dir}/CMakeLists.txt
set(GMOCK_DIR ${gmock_path}
    CACHE PATH "The path to the GoogleMock test framework.")

set(GTEST_DIR ${gtest_path}
    CACHE PATH "The path to the GoogleTest test framework.")

set(BUILD_TESTING ON)
enable_testing()

if ("\${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
  # force this option to ON so that Google Test will use /MD instead of /MT
  # /MD is now the default for Visual Studio, so it should be our default, too
  option(gtest_force_shared_crt
  "Use shared (DLL) run-time lib even when Google Test is built as static lib."
  ON)
elseif (APPLE)
  add_definitions(-DGTEST_USE_OWN_TR1_TUPLE=1)
endif()

add_subdirectory(\${GMOCK_DIR} \${CMAKE_BINARY_DIR}/gmock)

include_directories(\${GMOCK_DIR}/gtest/include \${GMOCK_DIR}/include)
include_directories(\${GTEST_DIR}/gtest/include \${GTEST_DIR}/include)
GOOGLETEST_GEN
}

####################################################################################
# tests/template Directory - CMakeLists.txt 
####################################################################################
test_template() {

echo "Generate test template CMakeLists.txt"

if [ $use_google_test = y ]; then
cat << TEST_TEMPLATE_GEN  >> ${proj_root}/${tests_dir}/${template_dir}/CMakeLists.txt

add_executable(test_gtest_template template_gtest.cpp)
target_link_libraries(test_gtest_template ${link_libraries} gmock_main)
add_test(test_gtest_template test_gtest_template)
TEST_TEMPLATE_GEN
fi #end if [ use_google_test = y ]

if [[ $use_boost_test = y ]] && [[ $use_boost = y ]]; then
cat << TEST_TEMPLATE_GEN  >> ${proj_root}/${tests_dir}/${template_dir}/CMakeLists.txt

add_executable(test_boosttest_template template_boosttest_.cpp)
target_link_libraries(test_boosttest_template ${link_libraries} \${Boost_LIBRARIES})
add_test(test_boosttest_template test_boosttest_template)
TEST_TEMPLATE_GEN
fi #end [[ use_boost_test = y ]] && [[ use_boost = y ]]

#if [[ $use_google_test = n ]] && [[ $use_boost_test = n ]]; then
cat << TEST_TEMPLATE_GEN  >> ${proj_root}/${tests_dir}/${template_dir}/CMakeLists.txt

add_executable(test_noframework_template test_noframework_template.cpp)
target_link_libraries(test_noframework_template ${link_libraries})
add_test(test_noframework_template test_noframework_template)
TEST_TEMPLATE_GEN
#fi #end if [[ use_google_test = n ]] && [[ use_boost_test = n ]]

test_cpp_template
}

#Test CPP Templates
test_cpp_template () {
echo "Generate test cpp templates"

if [ $use_google_test = y ]; then
echo " - Generate gtest cpp template"
cat << TEST_TEMPLATE_CPP_GEN  >> ${proj_root}/${tests_dir}/${template_dir}/template_gtest.cpp
#include <iostream>
#include <string>
#include "gtest/gtest.h"

//your includes go here.
#include "template/module_template.h"

//Test template
TEST(MODULE, test0) {
   bool a = true;
   EXPECT_EQ(a, module_template());
}
TEST_TEMPLATE_CPP_GEN
fi #end if [ use_google_test = y ]

if [[ $use_boost_test = y ]] && [[ $use_boost = y ]]; then
echo " - Generate Boost test cpp template"
cat << TEST_TEMPLATE_CPP_GEN  >> ${proj_root}/${tests_dir}/${template_dir}/template_boosttest.cpp
#define BOOST_TEST_MAIN
#include <boost/test/unit_test.hpp>

#include "template/module_template.h"

BOOST_AUTO_TEST_CASE(Test_BOOST_TEST_Template)
{  
   bool a = true;
   BOOST_REQUIRE_EQUAL(true, module_template());
}
TEST_TEMPLATE_CPP_GEN
fi #end [[ use_boost_test = y ]] && [[ use_boost = y ]]

#if [[ $use_google_test = n ]] && [[ $use_boost_test = n ]]; then
echo " - Generate No-framework cpp template"
cat << TEST_TEMPLATE_CPP_GEN  >> ${proj_root}/${tests_dir}/${template_dir}/test_noframework_template.cpp
#include <iostream>

#include "template/module_template.h"

int main(int argc, char* argv[]) 
{
  if(module_template()) {
    std::cout << "Unit Test Template" << std::endl;
  }
  return 0;
}
TEST_TEMPLATE_CPP_GEN
#fi #end if [[ use_google_test = n ]] && [[ use_boost_test = n ]]

}

####################################################################################
# SRC Directory - CMakeLists.txt 
####################################################################################
src_cmake () {

echo "Generate src CMakeLists.txt"
cat << SRC_TEMPLATE_GEN  >> ${proj_root}/${src_dir}/CMakeLists.txt

add_subdirectory(${template_dir})

SRC_TEMPLATE_GEN

src_template

}

src_template () {
echo "Generate src templates CMakeLists.txt"
cat << TEST_TEMPLATE_GEN  >> ${proj_root}/${src_dir}/${template_dir}/CMakeLists.txt
project(${link_libraries} C CXX)

file(GLOB SOURCE_FILES "*.cpp")
file(GLOB HEADER_FILES "*.h")

add_library(${link_libraries} \${SOURCE_FILES} \${HEADER_FILES})
target_link_libraries(${link_libraries} ${external_libs})

TEST_TEMPLATE_GEN
 
echo " - Generate src templates ( .cpp .h ) statically buildable."
cat << SRC_TEMPLATE_HEADER_GEN  >> ${proj_root}/${src_dir}/${template_dir}/module_template.h
#ifndef _MODULE_TEMPLATE_HH_
#define _MODULE_TEMPALTE_HH__

bool module_template();

#endif
SRC_TEMPLATE_HEADER_GEN

cat << SRC_TEMPLATE_CPP_GEN  >> ${proj_root}/${src_dir}/${template_dir}/module_template.cpp

#include "module_template.h"

bool module_template() {
  return true;
}
SRC_TEMPLATE_CPP_GEN

}

####################################################################################
# app Directory - CMakeLists.txt 
####################################################################################
app_cmake () {
echo "Generate app templatee CMakeLists.txt"
cat << TEST_TEMPLATE_GEN  >> ${proj_root}/${app_dir}/CMakeLists.txt
project(${link_libraries} C CXX)

file(GLOB SOURCE_FILES "*.cpp")
file(GLOB HEADER_FILES "*.h")

add_executable(app \${SOURCE_FILES} \${HEADER_FILES})
target_link_libraries(app ${link_libraries} ${external_libs})
TEST_TEMPLATE_GEN

app_template

}

app_template () {
echo "Generate app template source file"
cat << APP_TEMPLATE_CPP_GEN  >> ${proj_root}/${app_dir}/app_template.cpp
#include <iostream>

#include "template/module_template.h"

int main(int argc, char *argv[]) 
{
  if(module_template()) {
    std::cout << "Application ${project_name} running" << std::endl;
  }
  return 0;
}
APP_TEMPLATE_CPP_GEN
}


####################################################################################
# benchmark Directory - CMakeLists.txt 
####################################################################################
benchmark_cmake () {
echo "Generate Benchmark template CMakeLists.txt"
cat << BENCHMARK_TEMPLATE_GEN  >> ${proj_root}/${benchmark_dir}/CMakeLists.txt
project(${link_libraries}_benchmark C CXX)

file(GLOB SOURCE_FILES "*.cpp")
file(GLOB HEADER_FILES "*.h")

add_executable(benchmark \${SOURCE_FILES} \${HEADER_FILES})
target_link_libraries(benchmark ${link_libraries} ${external_libs})
BENCHMARK_TEMPLATE_GEN

benchmark_template

}

benchmark_template () {
echo "Generate Benchmark template source file"
cat << BENCHMARK_CPP_TEMPLATE_GEN  >> ${proj_root}/${benchmark_dir}/benchmark_template.cpp
#include <iostream>

#include "template/module_template.h"

int main(int argc, char *argv[]) 
{
  if(module_template()) {
    std::cout << "Benchmark ${project_name} running" << std::endl;
  }
  return 0;
}
BENCHMARK_CPP_TEMPLATE_GEN
}

####################################################################################
# main
####################################################################################
main () {
  verifications
  generate_external_libs
  create_dir_tree
  root_project_cmake
  tests_cmake
  src_cmake
  app_cmake
  benchmark_cmake
}

main
