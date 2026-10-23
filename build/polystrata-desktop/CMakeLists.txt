# Strata Engine - top-level build (P1.S1).
#
# The build version the packaging step reports (`package_terminal.py::_source_version`) and the
# Linux CUDA/HIP scripts read from `project(... VERSION ...)`. Kept in sync with the desktop
# application version in src-tauri/Cargo.toml so the terminal archive, the installer and the
# on-screen app version all agree.

cmake_minimum_required(VERSION 3.24)
project(strata VERSION 0.2.3 LANGUAGES CXX)
option(STRATA_ENABLE_SYCL "EXPERIMENTAL: build the Intel Arc (SYCL) engine from sycl/" OFF)
if(STRATA_ENABLE_SYCL)
  if(STRATA_ENABLE_CUDA OR STRATA_ENABLE_HIP)
    message(FATAL_ERROR "STRATA_ENABLE_SYCL is a separate backend; leave STRATA_ENABLE_CUDA and STRATA_ENABLE_HIP off")
  endif()
  add_subdirectory(sycl)
  return()
endif()

if(STRATA_ENABLE_CUDA)
  add_subdirectory(metal)
elseif(STRATA_ENABLE_HIP)
  add_subdirectory(sycl)
else()
  add_subdirectory(strata)
endif()
