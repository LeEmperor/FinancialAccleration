cmake_minimum_required(VERSION 3.10)

project(bruh)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_STANDARD 11)

find_package(cpprestsdk REQUIRED)
# find_package(crypto REQUIRED)
# addlibrary(RESTLIB)

add_executable(exec src/main.cpp)
target_link_libraries(exec PRIVATE cpprestsdk::cpprest crypto)


