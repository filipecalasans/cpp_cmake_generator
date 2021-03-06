# CMake Project Generator

A CMake project directory tree generator for c++

## Description

This script generates a C/C++ project directory tree ready to go. It provides boilerplates that demonstrate how to link your different modules/application/unit test modules together and with external dependencies.

This script can also generate projects that links to *googletest*, *boost*, *boost unit test framework* and *openssl*. It provides those who aren't very familiar with CMake syntax with a project directory tree redy to go.

## Example`

Inside the script file *bootstrap_cpp_project.sh*, you can configure the following parameters of your project:

```bash
cmake_version=3.0
boost_version=1.59

#Look in the default system installation path.
openssl_path="" 
boost_path="~/Downloads/boost_1_68_0" 
gtest_path="~/Documents/Workspace/googletest/googletest"
gmock_path="~/Workspace/googletest/googlemock"

use_boost=y   #y/n
use_openssl=y #y/n

#If you choose Boost Test, you must set use_boost=y
use_google_test=y  #y/n
use_boost_test=y   #y/n
```

Execute the script passing the project name as argument:

```console
$ ./bootstrap_cpp_project.sh my_project
```

This is the directory tree generated
```  
  .my_project
├── app
├── CMakeLists.txt
├── app
|   ├── CMakeLists.txt
|   └── app_template.cpp
├── benchmark
|   ├── CMakeLists.txt
|   └── benchmark_template.cpp
├── build
├── src
|   ├── CMakeLists.txt
|   └── template
|   |   ├── CMakeLists.txt
|   |   ├── module_template.h
|   |   └── module_template.cpp
├── tests
|   ├── CMakeLists.txt
|   └── template
|   |   ├── CMakeLists.txt
|   |   ├── template_boosttest.cpp
|   |   ├── test_noframework_template.cpp
|   |   └── template_gtest.cpp
```

To build the template poject, execute the following commands in the folder build:

```console
$ cd my_project/build && cmake ../ && make
```
