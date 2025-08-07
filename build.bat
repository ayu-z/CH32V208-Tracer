@echo off

set PATH=.\Toolchain;%PATH%
if not exist build mkdir build
cd build
cmake -GNinja -DBUILD_WITH_BLE=ON ..
ninja

