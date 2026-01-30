#!/bin/bash
# 保存为 build_pyqt5_wheel.sh

set -e  # 遇到错误立即退出

echo "========================================="
echo "PyQt5 Wheel 构建脚本"
echo "========================================="

# 1. 设置工作目录
WORK_DIR="$HOME/tmp/pyqt5_tmp/pyqt5_wheel_package"
echo -e "\n[1/8] 清理并创建工作目录: $WORK_DIR"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# 2. 检查 PyQt5 是否已安装
echo -e "\n[2/8] 检查 PyQt5 安装..."
python3 << 'PYEOF'
import sys
try:
    import PyQt5
    from PyQt5 import QtCore
    print(f"✓ 找到 PyQt5 版本: {QtCore.PYQT_VERSION_STR}")
    print(f"✓ Qt 版本: {QtCore.QT_VERSION_STR}")
except ImportError as e:
    print(f"✗ 错误: PyQt5 未安装")
    print(f"  {e}")
    sys.exit(1)
PYEOF

if [ $? -ne 0 ]; then
    echo "请先安装 PyQt5"
    exit 1
fi

# 3. 获取系统信息
echo -e "\n[3/8] 获取系统信息..."
PYTHON_VERSION=$(python3 -c "import sys; print(f'cp{sys.version_info.major}{sys.version_info.minor}')")
ABI_TAG=$(python3 -c "import sys; print(f'cp{sys.version_info.major}{sys.version_info.minor}')")
PLATFORM=$(python3 -c "import sysconfig; print(sysconfig.get_platform().replace('-', '_').replace('.', '_'))")

echo "  Python 标签: $PYTHON_VERSION"
echo "  ABI 标签: $ABI_TAG"
echo "  平台标签: $PLATFORM"

# 4. 复制 PyQt5 文件
echo -e "\n[4/8] 复制 PyQt5 文件..."
python3 << 'PYEOF'
import os
import shutil
import PyQt5

src_path = os.path.dirname(PyQt5.__file__)
dst_path = './PyQt5'

print(f"  源路径: {src_path}")
print(f"  目标路径: {os.path.abspath(dst_path)}")

# 复制整个目录，保留符号链接
shutil.copytree(src_path, dst_path, symlinks=True)

# 统计文件
total_files = 0
so_files = 0
for root, dirs, files in os.walk(dst_path):
    total_files += len(files)
    so_files += len([f for f in files if f.endswith('.so')])

print(f"  ✓ 已复制 {total_files} 个文件 (包含 {so_files} 个 .so 文件)")
PYEOF

# 5. 创建 setup.py
echo -e "\n[5/8] 创建 setup.py..."
cat > setup.py << 'SETUP_PY_EOF'
from setuptools import setup, find_packages
from setuptools.dist import Distribution
from wheel.bdist_wheel import bdist_wheel as _bdist_wheel
import os
import sys

class BinaryDistribution(Distribution):
    """标记这是一个包含二进制文件的包"""
    def has_ext_modules(self):
        return True

class CustomBdistWheel(_bdist_wheel):
    """自定义 wheel 构建，强制使用平台标签"""
    def finalize_options(self):
        _bdist_wheel.finalize_options(self)
        self.root_is_pure = False
    
    def get_tag(self):
        # 获取正确的标签
        python_tag = f'cp{sys.version_info.major}{sys.version_info.minor}'
        abi_tag = python_tag
        plat_tag = self.plat_name.replace('-', '_').replace('.', '_')
        return python_tag, abi_tag, plat_tag

# 收集所有文件
def find_all_files(directory):
    """递归查找所有文件"""
    matches = []
    for root, dirnames, filenames in os.walk(directory):
        for filename in filenames:
            # 获取相对于 directory 的路径
            file_path = os.path.join(root, filename)
            rel_path = os.path.relpath(file_path, directory)
            matches.append(rel_path)
    return matches

package_data_files = find_all_files('PyQt5')
print(f"打包 {len(package_data_files)} 个文件...")

setup(
    name='PyQt5',
    version='5.15.2',
    description='Python bindings for Qt5',
    packages=['PyQt5'],
    package_data={
        'PyQt5': package_data_files,
    },
    include_package_data=True,
    distclass=BinaryDistribution,
    cmdclass={
        'bdist_wheel': CustomBdistWheel,
    },
    zip_safe=False,
    python_requires='>=3.6',
)
SETUP_PY_EOF

echo "  ✓ setup.py 已创建"

# 6. 创建 MANIFEST.in
echo -e "\n[6/8] 创建 MANIFEST.in..."
cat > MANIFEST.in << 'MANIFEST_EOF'
recursive-include PyQt5 *
MANIFEST_EOF

echo "  ✓ MANIFEST.in 已创建"

# 7. 安装构建依赖
echo -e "\n[7/8] 安装构建依赖..."
pip install --upgrade wheel setuptools -q

# 8. 构建 wheel
echo -e "\n[8/8] 构建 wheel 文件..."
python3 setup.py bdist_wheel

# 显示结果
echo -e "\n========================================="
echo "构建完成！"
echo "========================================="
echo -e "\nWheel 文件位置:"
ls -lh dist/*.whl

echo -e "\nWheel 文件名:"
basename dist/*.whl

echo -e "\n验证 wheel 内容 (前 20 行):"
unzip -l dist/*.whl | head -20

echo -e "\n检查关键模块:"
unzip -l dist/*.whl | grep -E "QtWidgets|QtCore|QtGui" | head -5

echo -e "\n========================================="
echo "安装测试命令:"
echo "  pip install $WORK_DIR/dist/*.whl"
echo "========================================="
