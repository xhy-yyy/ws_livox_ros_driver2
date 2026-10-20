#!/usr/bin/env bash
set -euo pipefail

driver_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source_dir="$(dirname -- "$driver_dir")"
if [[ "$(basename -- "$source_dir")" != src ]]; then
  printf 'Clone this driver under a ROS2 workspace src/ directory first.\n' >&2
  exit 1
fi
workspace_dir="$(dirname -- "$source_dir")"
sdk_source="${LIVOX_SDK2_SOURCE:-$source_dir/Livox-SDK2}"
sdk_prefix="${LIVOX_SDK2_PREFIX:-$workspace_dir/.deps/livox_sdk2}"
sdk_build="$workspace_dir/.deps/build_livox_sdk2"
ros_setup="${ROS_SETUP_FILE:-/opt/ros/humble/setup.bash}"
build_jobs="${BUILD_JOBS:-2}"

if [[ ! -f "$sdk_source/CMakeLists.txt" || ! -f "$ros_setup" ]]; then
  printf 'SDK2 source or ROS2 Humble setup is missing; see README.md.\n' >&2
  exit 1
fi
if [[ ! "$build_jobs" =~ ^[1-9][0-9]*$ ]]; then
  printf 'BUILD_JOBS must be a positive integer.\n' >&2
  exit 1
fi
set +u
source "$ros_setup"
set -u

cmake -S "$sdk_source" -B "$sdk_build" \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$sdk_prefix"
cmake --build "$sdk_build" --parallel "$build_jobs"
cmake --install "$sdk_build"

export CMAKE_PREFIX_PATH="$sdk_prefix${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"
export LD_LIBRARY_PATH="$sdk_prefix/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export CMAKE_BUILD_PARALLEL_LEVEL="$build_jobs"
export MAKEFLAGS="${MAKEFLAGS:--j$build_jobs}"

# Select the ROS2 manifest without clearing the workspace's existing build directories.
cp "$driver_dir/package_ROS2.xml" "$driver_dir/package.xml"
cd "$workspace_dir"
colcon build --base-paths "$driver_dir" --packages-select livox_ros_driver2 \
  --parallel-workers 1 \
  --cmake-args -DROS_EDITION=ROS2 -DHUMBLE_ROS=humble \
    -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF
