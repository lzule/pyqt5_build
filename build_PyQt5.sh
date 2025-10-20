#!/bin/bash

# PyQt5 �Զ���װ�ű����Ż��棩
# ʹ�÷���: chmod +x install_pyqt5.sh && ./install_pyqt5.sh

set -e  # �������������˳�

echo "=========================================="
echo "��ʼ��װ PyQt5"
echo "=========================================="

# ��ǰ��ȡ sudo Ȩ��
echo "������ sudo ���루ֻ������һ�Σ�:"
sudo -v

# �ں�̨���� sudo Ȩ��
while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &

# ����Ҫ���ļ��Ƿ����
if [ ! -f "./PyQt5-5.15.2.tar.gz" ]; then
    echo "����: �Ҳ��� PyQt5-5.15.2.tar.gz"
    exit 1
fi

if [ ! -f "./sip-4.19.25.tar.gz" ]; then
    echo "����: �Ҳ��� sip-4.19.25.tar.gz"
    exit 1
fi

if [ ! -f "./cmake-3.26.0-linux-aarch64.tar.gz" ]; then
    echo "����: �Ҳ��� cmake-3.26.0-linux-aarch64.tar.gz"
    exit 1
fi

# ��ѹ������ CMake
echo "=========================================="
echo "���� 1: ��ѹ������ CMake 3.26.0"
echo "=========================================="
tar -xzf ./cmake-3.26.0-linux-aarch64.tar.gz
export PATH="$(pwd)/cmake-3.26.0-linux-aarch64/bin:$PATH"
export CMAKE_ROOT="$(pwd)/cmake-3.26.0-linux-aarch64"

# ��֤ CMake �汾
CMAKE_VERSION=$(cmake --version | head -n1)
echo "��ǰʹ�õ� CMake �汾: $CMAKE_VERSION"

# �Ȱ�װϵͳ����
echo "=========================================="
echo "���� 2: ��װϵͳ����"
echo "=========================================="
sudo apt-get update
sudo apt-get install -y qt5-qmake qtbase5-dev qtbase5-dev-tools

# ��� qmake �Ƿ����
if ! command -v qmake &> /dev/null; then
    echo "����: qmake δ�ҵ�"
    exit 1
fi

QMAKE_PATH=$(which qmake)
echo "ʹ�� qmake ·��: $QMAKE_PATH"

# ��ѹ�ļ�
echo "=========================================="
echo "���� 3: ��ѹԴ���ļ�"
echo "=========================================="
tar -xzf ./PyQt5-5.15.2.tar.gz
tar -xzf ./sip-4.19.25.tar.gz

# ��װ SIP
echo "=========================================="
echo "���� 4: ���밲װ SIP"
echo "=========================================="
cd sip-4.19.25/
python configure.py --sip-module PyQt5.sip
make -j4
sudo make install
cd ..

# ���밲װ PyQt5
echo "=========================================="
echo "���� 4: ���밲װ PyQt5"
echo "=========================================="
cd PyQt5-5.15.2
python configure.py --qmake "$QMAKE_PATH"
make -j4
sudo make install
cd ..

# ���в���
echo "=========================================="
echo "���� 5: ���в���"
echo "=========================================="
if [ -f "qt_test.py" ]; then
    python qt_test.py
    echo "=========================================="
    echo "��װ��ɲ����Գɹ���"
    echo "=========================================="
else
    echo "����: �Ҳ��� qt_test.py �����ļ�"
    echo "=========================================="
    echo "��װ��ɣ�"
    echo "=========================================="
fi