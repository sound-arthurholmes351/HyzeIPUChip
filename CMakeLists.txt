cmake_minimum_required(VERSION 3.20)
project(HyzeIpuDriver)

set(CMAKE_CXX_STANDARD 20)
find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBPCI REQUIRED libpci)

add_executable(hyze_ipu_driver
    hyze_ipu_pcie_driver.cpp
    onnx_model.cpp
)

target_link_libraries(hyze_ipu_driver ${LIBPCI_LIBRARIES} pthread)
target_include_directories(hyze_ipu_driver PRIVATE ${LIBPCI_INCLUDE_DIRS})
target_compile_options(hyze_ipu_driver PRIVATE ${LIBPCI_CFLAGS_OTHER})
