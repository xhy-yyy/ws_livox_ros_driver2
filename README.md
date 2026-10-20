# Livox MID360 ROS 2 Driver

面向单台 Livox MID360 的 ROS 2 驱动工程，提供点云与 IMU 数据接入、设备网络配置，以及构建和启动脚本，可用于激光惯性里程计、定位建图等应用的数据采集。

本项目由 [xhy-yyy](https://github.com/xhy-yyy) 维护，基于 Livox ROS Driver 2 进行配置适配与工程整理，默认面向 **Ubuntu 22.04 / ROS 2 Humble**。上游来源与版本记录见 [CREDITS.md](CREDITS.md) 和 [SOURCE_VERSION.json](SOURCE_VERSION.json)。

## 功能特性

- 支持单台 MID360 的点云与内置 IMU 数据发布。
- 默认以 **20 Hz** 发布 Livox `CustomMsg` 点云，保留逐点时间信息，便于接入 Point-LIO 等处理节点。
- 采用固定版本的 Livox SDK2，提供工作区本地构建与安装流程。
- 提供统一的构建、启动入口及网络、话题和参数说明。

本文覆盖单 MID360 的配置与使用流程。仓库保留的 HAP 和多雷达配置示例需按实际设备单独配置。

## 环境要求

| 项目 | 配置 |
| --- | --- |
| 操作系统 | Ubuntu 22.04 |
| ROS 版本 | ROS 2 Humble |
| 雷达型号 | Livox MID360，单设备 |
| SDK | Livox SDK2 1.2.5，固定提交见下文 |
| 构建工具 | CMake、colcon |
| ROS 包名 | `livox_ros_driver2` |

SDK2 与驱动已在 x86_64 / ROS 2 Humble 环境完成编译验证，尚未进行雷达实机测试。

## 安装与构建

### 1. 安装依赖

安装 ROS 2 Humble 后，执行以下命令安装构建依赖：

```bash
sudo apt update
sudo apt install build-essential cmake pkg-config libapr1-dev libpcl-dev \
  python3-colcon-common-extensions ros-humble-ament-cmake-auto \
  ros-humble-pcl-conversions ros-humble-rosbag2
```

### 2. 获取源码

驱动源码应位于 ROS 工作区的 `src/` 目录。以下命令以 `~/ws_livox` 为工作区：

```bash
mkdir -p ~/ws_livox/src

git clone https://github.com/xhy-yyy/ws_livox_ros_driver2.git \
  ~/ws_livox/src/livox_ros_driver2

git clone https://github.com/Livox-SDK/Livox-SDK2.git \
  ~/ws_livox/src/Livox-SDK2

git -C ~/ws_livox/src/Livox-SDK2 checkout \
  6a940156dd7151c3ab6a52442d86bc83613bd11b
```

固定 SDK2 提交用于保持依赖版本一致，建议首次构建时采用上述版本。

### 3. 构建工程

在未加载其他同名工作区的终端中执行：

```bash
bash ~/ws_livox/src/livox_ros_driver2/scripts/build_humble.sh
```

脚本依次构建 SDK2、将其安装至 `ws_livox/.deps/livox_sdk2`，并生成 ROS 2 包清单、构建驱动。SDK 安装无需写入系统目录。

可通过环境变量调整构建配置：

| 环境变量 | 默认值 | 说明 |
| --- | --- | --- |
| `ROS_SETUP_FILE` | `/opt/ros/humble/setup.bash` | ROS 环境脚本 |
| `LIVOX_SDK2_SOURCE` | `<工作区>/src/Livox-SDK2` | SDK2 源码目录 |
| `LIVOX_SDK2_PREFIX` | `<工作区>/.deps/livox_sdk2` | SDK2 安装目录 |
| `BUILD_JOBS` | `2` | 构建并行数 |

例如，调整构建并行数：

```bash
BUILD_JOBS=4 bash ~/ws_livox/src/livox_ros_driver2/scripts/build_humble.sh
```

使用自定义 SDK 安装目录时，构建和启动应设置相同的 `LIVOX_SDK2_PREFIX`。

## 网络配置

默认网络参数位于 [MID360_config.json](config/MID360_config.json)：

| 设备 | 默认 IP 地址 |
| --- | --- |
| MID360 雷达 | `192.168.1.100` |
| 接收主机网口 | `192.168.1.50` |

将雷达连接至主机网口，并为该网口配置与雷达处于同一子网的静态地址。配置文件中的主机地址应与网口的实际地址一致。

- 雷达地址：修改 `lidar_configs` 中对应设备的 `ip`。
- 主机地址：修改 `MID360.host_net_info` 下的 `cmd_data_ip`、`push_msg_ip`、`point_data_ip` 和 `imu_data_ip`。

如果雷达已使用其他地址，请按实际地址调整配置。修改配置文件后需重新构建，更新安装目录中的配置副本。

## 启动与数据接口

### 1. 启动雷达驱动（终端 1）

完成构建和网络配置后，先启动 MID360 驱动。以下命令以 `~/ws_livox` 和 `~/ws_mid360` 为工作区路径；使用其他目录时，请替换为实际路径。

```bash
source /opt/ros/humble/setup.bash
source ~/ws_livox/install/setup.bash
export LD_LIBRARY_PATH="$HOME/ws_livox/.deps/livox_sdk2/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

ros2 launch livox_ros_driver2 msg_MID360_launch.py
```

`LD_LIBRARY_PATH` 用于加载本工程安装的 SDK2 动态库。使用自定义 `LIVOX_SDK2_PREFIX` 时，将上述 SDK 路径替换为该目录下的 `lib`。

也可使用脚本完成相同的环境加载和启动：

```bash
bash ~/ws_livox/src/livox_ros_driver2/scripts/run_mid360.sh
```

启动后保持此终端运行，驱动持续发布点云与 IMU 数据。

### 默认发布话题

| 话题 | 消息类型 | 说明 |
| --- | --- | --- |
| `/livox/lidar` | `livox_ros_driver2/msg/CustomMsg` | Livox 自定义点云，默认 20 Hz |
| `/livox/imu` | `sensor_msgs/msg/Imu` | MID360 内置 IMU 数据 |

默认消息坐标系为 `livox_frame`。`20 Hz` 为点云组帧与发布频率配置，IMU 数据按接收到的数据独立发布。

在另一个终端加载环境后，可检查话题类型和点云接收频率：

```bash
source /opt/ros/humble/setup.bash
source ~/ws_livox/install/setup.bash

ros2 topic info /livox/lidar
ros2 topic hz /livox/lidar
```

### 发布参数

默认启动参数位于 [msg_MID360_launch.py](launch_ROS2/msg_MID360_launch.py)：

| 参数 | 默认值 | 说明 |
| --- | --- | --- |
| `xfer_format` | `1` | 发布 Livox `CustomMsg` 点云 |
| `multi_topic` | `0` | 使用共享点云和 IMU 话题 |
| `publish_freq` | `20.0` | 点云发布频率，单位 Hz |
| `frame_id` | `livox_frame` | 点云消息坐标系 |

上述参数对应本项目默认启动文件，其他启动文件使用各自的参数。修改启动文件后需重新构建。

## Point-LIO 接入

配套定位建图工程：[Point-LIO_ROS2](https://github.com/xhy-yyy/ws_Point-LIO_ROS2)。

使用该工程时，保持驱动输出为 `CustomMsg`，并将 Point-LIO 的点云、IMU 输入分别配置为 `/livox/lidar` 和 `/livox/imu`。雷达驱动与定位节点分别启动，定位参数和外参配置见配套工程说明。

### 2. 启动 Point-LIO（终端 2）

完成配套工程构建，并确认驱动已发布点云和 IMU 数据后，在另一个终端执行：

```bash
source /opt/ros/humble/setup.bash
source ~/ws_livox/install/setup.bash
source ~/ws_mid360/install/setup.bash
export LD_LIBRARY_PATH="$HOME/ws_livox/.deps/livox_sdk2/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

ros2 launch point_lio mapping_mid360.launch.py
```

每个终端需分别加载环境。若已在终端中配置好上述环境，可直接依次运行两条 `ros2 launch` 命令。

Point-LIO 默认关闭 RViz；如需显示建图结果，将其启动命令替换为：

```bash
ros2 launch point_lio mapping_mid360.launch.py rviz:=true
```

## 常见问题

**启动后没有点云或 IMU 数据**

核对雷达实际 IP、主机网口地址及 JSON 中的接收地址，确认使用的是单 MID360 配置，并检查是否存在其他驱动实例占用接收端口。

**找不到 SDK 动态库**

先完成 `build_humble.sh` 构建，再使用 `run_mid360.sh` 启动。若指定了 `LIVOX_SDK2_PREFIX`，启动时需使用同一安装目录。

**修改配置后没有生效**

运行时读取安装目录中的配置和启动文件。修改源码目录后重新执行构建脚本，再启动驱动。

## 来源与许可证

本项目基于 [Livox ROS Driver 2](https://github.com/Livox-SDK/livox_ros_driver2) 和 [Livox SDK2](https://github.com/Livox-SDK/Livox-SDK2) 进行工程适配，保留原有版权声明和第三方许可证。

- [来源与维护记录](CREDITS.md)
- [上游版本记录](SOURCE_VERSION.json)
- [原版使用说明](README_UPSTREAM.md)
- [许可证及第三方声明](LICENSE.txt)
