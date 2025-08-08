set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY")
cmake_minimum_required(VERSION 3.20)


# 工具链设置
set(TOOLPATH ${CMAKE_SOURCE_DIR}/Toolchain/RISC-V\ Embedded\ GCC/bin/riscv-none-embed-)

if (WIN32)
    MESSAGE(STATUS "Now is windows!")
    set(CMAKE_C_COMPILER ${TOOLPATH}gcc.exe)
    set(CMAKE_CXX_COMPILER ${TOOLPATH}g++.exe)
    set(CMAKE_ASM_COMPILER ${TOOLPATH}gcc.exe)
    set(CMAKE_AR ${TOOLPATH}ar.exe)
    set(CMAKE_OBJCOPY ${TOOLPATH}objcopy.exe)
    set(CMAKE_OBJDUMP ${TOOLPATH}objdump.exe)
    set(SIZE ${TOOLPATH}size.exe)
elseif (UNIX)
    MESSAGE(STATUS "Now is UNIX-like OS!")
    set(CMAKE_C_COMPILER ${TOOLPATH}gcc)
    set(CMAKE_CXX_COMPILER ${TOOLPATH}g++)
    set(CMAKE_ASM_COMPILER ${TOOLPATH}gcc)
    set(CMAKE_AR ${TOOLPATH}ar)
    set(CMAKE_OBJCOPY ${TOOLPATH}objcopy)
    set(CMAKE_OBJDUMP ${TOOLPATH}objdump)
    set(SIZE ${TOOLPATH}size)
else ()
    MESSAGE(FATAL_ERROR "Unsupported system!")
endif ()

# 项目选项
option(BUILD_WITH_BLE "=== Project USE BLE ===" OFF)
option(BUILD_WITH_LWNS "=== Project USE LWNS ===" OFF)
option(BUILD_WITH_NETLIB "=== Project USE NET LIB ===" OFF)
option(BUILD_WITH_FREERTOS "=== Project USE FreeRTOS ===" OFF)
option(BLE_MAC "=== Use custom BLE MAC address ===" OFF)

# 项目设置
project(ch32v208-ninja C CXX ASM)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_C_STANDARD 99)

# 编译参数
add_compile_options(-march=rv32imac -mabi=ilp32 -msmall-data-limit=8 -msave-restore)
add_compile_options(-fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -fno-common)
add_compile_options(-O2 -g)
add_compile_options(-Wall)

# 添加预处理器定义
if(BLE_MAC)
    add_compile_definitions(BLE_MAC=TRUE)
endif()

# 添加子目录以获取源文件和配置
add_subdirectory(SDK)
add_subdirectory(APP)

# 链接参数 (使用从SDK导出的链接脚本)
add_link_options(-T ${SDK_LINKER_SCRIPT})
add_link_options(-march=rv32imac -mabi=ilp32 -nostartfiles -Xlinker --gc-sections -Wl,--print-memory-usage -Wl,-Map,${PROJECT_NAME}.map --specs=nano.specs --specs=nosys.specs)

# 创建主可执行文件，使用所有源文件
add_executable(${PROJECT_NAME}.elf 
    ${APP_SOURCES}
    ${SDK_CORE_SOURCES}
)

# 设置包含目录
target_include_directories(${PROJECT_NAME}.elf PRIVATE 
    ${SDK_CORE_INCLUDE_DIRS} 
    ${APP_INCLUDE_DIRS}
)

# 链接静态库
if(BUILD_WITH_BLE)
    target_link_libraries(${PROJECT_NAME}.elf ${BLE_STATIC_LIB})
    
    if(BUILD_WITH_LWNS)
        target_link_libraries(${PROJECT_NAME}.elf ${LWNS_STATIC_LIB})
    endif()
endif()

if(BUILD_WITH_NETLIB)
    target_link_libraries(${PROJECT_NAME}.elf ${NETLIB_STATIC_LIB})
endif()

# 输出hex和bin文件
set(HEX_FILE ${PROJECT_BINARY_DIR}/${PROJECT_NAME}.hex)
set(BIN_FILE ${PROJECT_BINARY_DIR}/${PROJECT_NAME}.bin)
set(LST_FILE ${PROJECT_BINARY_DIR}/${PROJECT_NAME}.lst)
add_custom_command(TARGET ${PROJECT_NAME}.elf POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -Oihex $<TARGET_FILE:${PROJECT_NAME}.elf> ${HEX_FILE}
        COMMAND ${CMAKE_OBJCOPY} -Obinary $<TARGET_FILE:${PROJECT_NAME}.elf> ${BIN_FILE}
        COMMAND ${CMAKE_OBJDUMP} --all-headers --demangle --disassemble $<TARGET_FILE:${PROJECT_NAME}.elf> > ${LST_FILE}
        COMMAND ${SIZE} --format=berkeley $<TARGET_FILE:${PROJECT_NAME}.elf>
)
