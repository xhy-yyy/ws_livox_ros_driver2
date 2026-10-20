#!/usr/bin/env bash
set -euo pipefail
driver_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
workspace_dir="$(cd -- "$driver_dir/../.." && pwd)"
ros_setup="${ROS_SETUP_FILE:-/opt/ros/humble/setup.bash}"
driver_setup="$workspace_dir/install/setup.bash"
sdk_prefix="${LIVOX_SDK2_PREFIX:-$workspace_dir/.deps/livox_sdk2}"
if [[ ! -f "$ros_setup" || ! -f "$driver_setup" ]]; then
  printf 'ROS or driver setup is missing; run scripts/build_humble.sh first.\n' >&2
  exit 1
fi
export LD_LIBRARY_PATH="$sdk_prefix/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
set +u
source "$ros_setup"
source "$driver_setup"
set -u
exec ros2 launch livox_ros_driver2 msg_MID360_launch.py "$@"
