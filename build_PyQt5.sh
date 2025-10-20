#!/bin/bash

# PyQt5 Automatic Installation Script (Optimized)
# Usage: chmod +x install_pyqt5.sh && ./install_pyqt5.sh

set -e  # Exit immediately on error

echo "=========================================="
echo "Starting PyQt5 Installation"
echo "=========================================="

# Request sudo privileges upfront
echo "Please enter sudo password (only once):"
sudo -v

# Keep sudo privileges alive in background
while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &

# Check if required files exist
if [ ! -f "./PyQt5-5.15.2.tar.gz" ]; then
    echo "Error: PyQt5-5.15.2.tar.gz not found"
    exit 1
fi

if [ ! -f "./sip-4.19.25.tar.gz" ]; then
    echo "Error: sip-4.19.25.tar.gz not found"
    exit 1
fi

if [ ! -f "./cmake-3.26.0-linux-aarch64.tar.gz" ]; then
    echo "Error: cmake-3.26.0-linux-aarch64.tar.gz not found"
    exit 1
fi

# Extract and configure CMake
echo "=========================================="
echo "Step 1: Extract and configure CMake 3.26.0"
echo "=========================================="
tar -xzf ./cmake-3.26.0-linux-aarch64.tar.gz
export PATH="$(pwd)/cmake-3.26.0-linux-aarch64/bin:$PATH"
export CMAKE_ROOT="$(pwd)/cmake-3.26.0-linux-aarch64"

# Verify CMake version
CMAKE_VERSION=$(cmake --version | head -n1)
echo "Current CMake version: $CMAKE_VERSION"

# Install system dependencies
echo "=========================================="
echo "Step 2: Install system dependencies"
echo "=========================================="
sudo apt-get update
sudo apt-get install -y qt5-qmake qtbase5-dev qtbase5-dev-tools

# Check if qmake is available
if ! command -v qmake &> /dev/null; then
    echo "Error: qmake not found"
    exit 1
fi

QMAKE_PATH=$(which qmake)
echo "Using qmake path: $QMAKE_PATH"

# Extract source files
echo "=========================================="
echo "Step 3: Extract source files"
echo "=========================================="
tar -xzf ./PyQt5-5.15.2.tar.gz
tar -xzf ./sip-4.19.25.tar.gz

# Install SIP
echo "=========================================="
echo "Step 4: Compile and install SIP"
echo "=========================================="
cd sip-4.19.25/
python configure.py --sip-module PyQt5.sip
make -j4
sudo make install
cd ..

# Compile and install PyQt5
echo "=========================================="
echo "Step 5: Compile and install PyQt5"
echo "=========================================="
cd PyQt5-5.15.2
python configure.py --qmake "$QMAKE_PATH"
make -j4
sudo make install
cd ..

# Run tests
echo "=========================================="
echo "Step 6: Run tests"
echo "=========================================="
if [ -f "qt_test.py" ]; then
    python qt_test.py
    echo "=========================================="
    echo "Installation completed and tested successfully!"
    echo "=========================================="
else
    echo "Warning: qt_test.py test file not found"
    echo "=========================================="
    echo "Installation completed!"
    echo "=========================================="
fi