#!/bin/bash

# PyQt5 自动安装脚本（优化版）
# 使用方法: chmod +x install_pyqt5.sh && ./install_pyqt5.sh

set -e  # 遇到错误立即退出

echo "=========================================="
echo "开始安装 PyQt5"
echo "=========================================="

# 提前获取 sudo 权限
echo "请输入 sudo 密码（只需输入一次）:"
sudo -v

# 在后台保持 sudo 权限
while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &

# 检查必要的文件是否存在
if [ ! -f "./PyQt5-5.15.2.tar.gz" ]; then
    echo "错误: 找不到 PyQt5-5.15.2.tar.gz"
    exit 1
fi

if [ ! -f "./sip-4.19.25.tar.gz" ]; then
    echo "错误: 找不到 sip-4.19.25.tar.gz"
    exit 1
fi

if [ ! -f "./cmake-3.26.0-linux-aarch64.tar.gz" ]; then
    echo "错误: 找不到 cmake-3.26.0-linux-aarch64.tar.gz"
    exit 1
fi

# 解压并配置 CMake
echo "=========================================="
echo "步骤 1: 解压并配置 CMake 3.26.0"
echo "=========================================="
tar -xzf ./cmake-3.26.0-linux-aarch64.tar.gz
export PATH="$(pwd)/cmake-3.26.0-linux-aarch64/bin:$PATH"
export CMAKE_ROOT="$(pwd)/cmake-3.26.0-linux-aarch64"

# 验证 CMake 版本
CMAKE_VERSION=$(cmake --version | head -n1)
echo "当前使用的 CMake 版本: $CMAKE_VERSION"

# 先安装系统依赖
echo "=========================================="
echo "步骤 2: 安装系统依赖"
echo "=========================================="
sudo apt-get update
sudo apt-get install -y qt5-qmake qtbase5-dev qtbase5-dev-tools

# 检查 qmake 是否可用
if ! command -v qmake &> /dev/null; then
    echo "错误: qmake 未找到"
    exit 1
fi

QMAKE_PATH=$(which qmake)
echo "使用 qmake 路径: $QMAKE_PATH"

# 解压文件
echo "=========================================="
echo "步骤 3: 解压源码文件"
echo "=========================================="
tar -xzf ./PyQt5-5.15.2.tar.gz
tar -xzf ./sip-4.19.25.tar.gz

# 安装 SIP
echo "=========================================="
echo "步骤 4: 编译安装 SIP"
echo "=========================================="
cd sip-4.19.25/
python configure.py --sip-module PyQt5.sip
make -j4
sudo make install
cd ..

# 编译安装 PyQt5
echo "=========================================="
echo "步骤 4: 编译安装 PyQt5"
echo "=========================================="
cd PyQt5-5.15.2
python configure.py --qmake "$QMAKE_PATH"
make -j4
sudo make install
cd ..

# 运行测试
echo "=========================================="
echo "步骤 5: 运行测试"
echo "=========================================="
if [ -f "qt_test.py" ]; then
    python qt_test.py
    echo "=========================================="
    echo "安装完成并测试成功！"
    echo "=========================================="
else
    echo "警告: 找不到 qt_test.py 测试文件"
    echo "=========================================="
    echo "安装完成！"
    echo "=========================================="
fi