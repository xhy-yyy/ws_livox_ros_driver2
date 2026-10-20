# livox_ros_driver2 — 单 MID360 ROS2 驱动工程

由 [xhy-yyy](https://github.com/xhy-yyy) 维护的单台 Livox MID360 驱动工程，面向
Ubuntu 22.04 / ROS2 Humble，提供实际网络配置、20 Hz 自定义点云输出，以及构建和启动脚本。

本项目基于 Livox 官方驱动进行配置与工程整理。来源和版本见 [CREDITS.md](CREDITS.md)，
原版说明见 [README_UPSTREAM.md](README_UPSTREAM.md)。

## 本工程提供的内容

- 默认雷达 IP `192.168.1.100`，接收主机 IP `192.168.1.50`。
- 默认以 20 Hz 输出 Livox `CustomMsg`，配套 Point-LIO 使用。
- SDK2 在工作区本地构建、安装，提供固定 SDK 版本和依赖搜索路径。
- 提供 ROS2 Humble 构建、启动脚本及配置说明。

ROS 包名为 `livox_ros_driver2`，输出话题为 `/livox/lidar` 和 `/livox/imu`，
默认坐标系为 `livox_frame`。

## 准备环境和构建

先安装 ROS2 Humble，再安装系统依赖：

```bash
sudo apt update
sudo apt install build-essential cmake pkg-config libapr1-dev libpcl-dev \
  python3-colcon-common-extensions ros-humble-ament-cmake-auto \
  ros-humble-pcl-conversions ros-humble-rosbag2
```

在未加载其他同名工作区的终端中，将仓库放到 `src/` 下，并准备官方 SDK2：

```bash
mkdir -p ~/ws_livox/src
git clone https://github.com/xhy-yyy/livox_ros_driver2.git ~/ws_livox/src/livox_ros_driver2
git clone https://github.com/Livox-SDK/Livox-SDK2.git ~/ws_livox/src/Livox-SDK2
git -C ~/ws_livox/src/Livox-SDK2 checkout 6a940156dd7151c3ab6a52442d86bc83613bd11b
bash ~/ws_livox/src/livox_ros_driver2/scripts/build_humble.sh
```

SDK 安装到 `ws_livox/.deps/livox_sdk2`。可用 `LIVOX_SDK2_SOURCE`、`LIVOX_SDK2_PREFIX`、
`ROS_SETUP_FILE` 指定路径，用 `BUILD_JOBS` 指定并行数。新脚本保留已有构建目录。

## 配置和运行

为连接雷达的网口配置与 JSON 一致的接收地址，并核对雷达实际 IP。

| 配置 | 文件 |
| --- | --- |
| 雷达和主机地址 | `config/MID360_config.json` |
| 点云格式和发布频率 | `launch_ROS2/msg_MID360_launch.py` |

```bash
bash ~/ws_livox/src/livox_ros_driver2/scripts/run_mid360.sh
```

配套定位工程为 [Point-LIO_ROS2](https://github.com/xhy-yyy/Point-LIO_ROS2)。
修改源码配置或启动文件后，重新构建以更新安装目录。

HAP 和混合配置保留为历史示例，默认单 MID360 启动不读取它们。
混合配置中两个雷达条目当前均为 `.100`，多雷达接入时需填写各设备实际地址。

## 维护和验证

维护分支为 `main`，本仓库从当前工程快照建立独立提交历史。
今后引入上游更新时，按补丁审阅、合入并验证。

本次整理前，相同的 SDK2、驱动源码和构建脚本已在 x86_64 / ROS2 Humble 环境编译通过。
独立发布整理未修改算法源码；未连接雷达做实机测试。
首次发布需将本项目推送到上述个人仓库后，克隆地址才可用于获取此版本。

许可证和第三方声明保留在 `LICENSE.txt` 及第三方目录中。
