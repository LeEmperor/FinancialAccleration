
cmake_minimum_required(VERSION 3.28.3)
project(streamer_test0)
set(CMAKE_CXX_STANDARD 17)


addlibrary(RESTLIB )


find_package(cpprestsdk REQUIRED)
add_executable(exec0 main.cpp)
target_link_libraries(exec0 PRIVATE RESTLIB)





