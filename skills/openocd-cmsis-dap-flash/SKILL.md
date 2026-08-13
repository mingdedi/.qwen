---
name: openocd-cmsis-dap-flash
description: 使用 OpenOCD 通过 CMSIS-DAP 调试器烧录固件、读写内存、halt/resume、dump flash 调试 ARM Cortex-M 芯片（STM32 等）。当用户提到"烧录固件"、"通过 CMSIS-DAP 烧录"、"openocd 烧录"、"调试 STM32"、"读写芯片内存"、"halt 芯片"、"dump flash"、"复位芯片"等关键词时触发
---

# OpenOCD + CMSIS-DAP 烧录调试专家

你是嵌入式烧录调试专家，通过 OpenOCD 命令行工具 + CMSIS-DAP 调试器，对 ARM Cortex-M 目标芯片执行烧录、内存读写、调试控制等操作。所有操作均通过 `run_shell_command` 调用 OpenOCD 完成，无需 GUI。

## When to use this skill

当用户需要通过 CMSIS-DAP 调试器对目标芯片做以下操作时触发：
- 烧录固件（.bin / .hex / .elf）
- 读写芯片内存（Flash / RAM / 外设寄存器）
- halt / resume / 复位 CPU
- dump 全片 Flash 到文件
- 读芯片 ID / Flash 容量 / UID
- 设断点、读寄存器、单步调试

## 环境前提

### 工具链路径（本机已验证）
- **OpenOCD 0.12.0**: `D:\xpack-openocd-0.12.0-3\bin\openocd.exe`
- **脚本目录**: `D:\xpack-openocd-0.12.0-3\openocd\scripts`
- **arm-none-eabi-gdb**: `C:\Program Files (x86)\GNU Arm Embedded Toolchain\10 2021.10\bin\`
- CMSIS-DAP 调试器使用 Windows 通用 HID 驱动即可，**无需 Zadig 替换驱动**

### 硬件配置（已验证）
- 调试器: CMSIS-DAP（USB VID 1FC9 PID 5601，固件 2.0.0）
- 目标板: STM32F407ZGT6（Cortex-M4 r0p1，1MB Flash，SWD DPIDR 0x2ba01477）
- 传输方式: SWD，时钟 2MHz

### 首次使用时的环境检测
若不确定工具是否就绪，先执行只读检测：
```
where openocd
"D:\xpack-openocd-0.12.0-3\bin\openocd.exe" --version 2>&1
```
确认 OpenOCD 存在后再继续。

## Step-by-step workflow

### 1. 连接验证（只读，确认链路通）
首次操作或排查问题时，先验证 CMSIS-DAP 能识别目标芯片：
```
"D:\xpack-openocd-0.12.0-3\bin\openocd.exe" -s "D:\xpack-openocd-0.12.0-3\openocd\scripts" -f interface/cmsis-dap.cfg -c "transport select swd" -f target/stm32f4x.cfg -c "adapter speed 2000" -c "init" -c "targets" -c "shutdown" 2>&1
```
**成功标志**: 输出 `Cortex-M4 r0p1 processor detected` + `Examination succeed`。
末尾若报 `not halted` 属正常（未发 halt 却 shutdown），不影响连接验证结论。

### 2. 烧录固件
**推荐用 `program` 命令**（自动 halt -> 擦除 -> 烧录 -> 校验 -> reset）：
```
openocd ... -f target/stm32f4x.cfg -c "init" -c "program firmware.elf verify reset exit"
```
- `.elf` 文件自带地址信息，直接用 `program`
- `.bin` 文件需指定地址：`program firmware.bin 0x08000000 verify reset exit`
- `.hex` 文件自带地址，直接 `program`
- `verify` = 烧录后回读校验；`reset` = 烧完复位运行；`exit` = 等同 shutdown

**完整命令**：
```
"D:\xpack-openocd-0.12.0-3\bin\openocd.exe" -s "D:\xpack-openocd-0.12.0-3\openocd\scripts" -f interface/cmsis-dap.cfg -c "transport select swd" -f target/stm32f4x.cfg -c "adapter speed 2000" -c "init" -c "program <固件路径> verify reset exit" 2>&1
```

### 3. halt / resume / 复位
```
-c "init" -c "halt"              # 停止 CPU
-c "init" -c "resume"            # 恢复运行
-c "init" -c "reset halt"        # 复位并停在复位向量
-c "init" -c "reset run"         # 复位并运行
```

### 4. 读写内存
```
-c "init" -c "halt" -c "mdw 0x08000000 4"     # 读 4 个 32-bit 字（Flash 起始/向量表）
-c "init" -c "halt" -c "mdh 0x1FFF7A22 1"     # 读 16-bit（Flash 容量寄存器）
-c "init" -c "halt" -c "mdb 0x40020010 8"     # 读 8 字节
-c "init" -c "halt" -c "mww 0x20000000 0xDEADBEEF"  # 写 32-bit 到 RAM
```
> 注意：halt 后连续执行多条内存命令时，若命令链中途 halt 未完全完成，后续 `mdw` 可能无输出。**解决：单独执行内存读取命令**，或确认 halt 成功后再接 mdw。

### 5. 读写寄存器
```
-c "init" -c "halt" -c "reg"                   # 列出所有寄存器
-c "init" -c "halt" -c "reg pc"                # 读 PC
-c "init" -c "halt" -c "reg r0 0x12345678"     # 写 R0
```

### 6. 读芯片信息
```
-c "init" -c "halt" -c "flash info 0"          # Flash 容量/扇区/保护状态
-c "init" -c "halt" -c "mdw 0xE0042000 1"      # DBGMCU_IDCODE（芯片型号）
-c "init" -c "halt" -c "mdw 0x1FFF7A10 3"      # UID（96-bit 唯一 ID）
-c "init" -c "halt" -c "mdh 0x1FFF7A22 1"      # Flash 大小寄存器（单位 KB）
```

### 7. dump 全片 Flash 到文件
```
-c "init" -c "halt" -c "dump_image flash_dump.bin 0x08000000 0x100000" -c "resume" -c "shutdown"
```
（STM32F407 1MB Flash = 0x100000 字节）

### 8. 擦除 Flash
```
-c "init" -c "halt" -c "flash erase_address 0x08000000 0x100000"   # 擦除指定范围
-c "init" -c "halt" -c "stm32f2x mass_erase 0"                      # 全片擦除
```

## Tool usage guidelines

- 所有 OpenOCD 调用通过 `run_shell_command` 执行，设置 `timeout: 30000`（烧录大固件时增至 120000）
- 命令末尾务必加 `2>&1`，否则 OpenOCD 的诊断信息（含错误）可能被 stderr 吞掉
- **命令链原则**: `-c "init"` 之后可接多个 `-c "命令"`，OpenOCD 按顺序执行。但 halt 状态不稳定时，建议每条关键命令单独成次调用
- **必须 halt 后才操作内存/寄存器**: Flash 读写、内存读写、寄存器访问均要求 CPU 处于 halted 态
- 烧录用 `program` 命令最省心（自动处理 halt/擦除/校验/复位）

## OpenOCD 连接模板

所有操作的基础前缀（替换 `<命令>` 部分）：
```
"D:\xpack-openocd-0.12.0-3\bin\openocd.exe" -s "D:\xpack-openocd-0.12.0-3\openocd\scripts" -f interface/cmsis-dap.cfg -c "transport select swd" -f target/stm32f4x.cfg -c "adapter speed 2000" -c "init" -c "<命令>" -c "shutdown" 2>&1
```

## 适配其他芯片

更换 `-f target/stm32f4x.cfg` 为对应芯片配置即可：
| 芯片 | target 配置 |
|------|------------|
| STM32F1xx | `target/stm32f1x.cfg` |
| STM32F4xx | `target/stm32f4x.cfg` |
| STM32G4xx | `target/stm32g4x.cfg` |
| STM32L4xx | `target/stm32l4x.cfg` |
| GD32F1xx | `target/stm32f1x.cfg`（兼容）|
| nRF52 | `target/nrf52.cfg` |

可用 `dir /b "D:\xpack-openocd-0.12.0-3\openocd\scripts\target\stm32*.cfg"` 列出所有支持的 STM32 配置。

## Examples

### 烧录 ELF 固件
```
"D:\xpack-openocd-0.12.0-3\bin\openocd.exe" -s "D:\xpack-openocd-0.12.0-3\openocd\scripts" -f interface/cmsis-dap.cfg -c "transport select swd" -f target/stm32f4x.cfg -c "adapter speed 2000" -c "init" -c "program C:\firmware\app.elf verify reset exit" 2>&1
```

### halt 后读向量表前 4 个字
```
... -c "init" -c "halt" -c "mdw 0x08000000 4" -c "resume" -c "shutdown" 2>&1
```

### 读芯片 ID 和 Flash 容量
```
... -c "init" -c "halt" -c "flash info 0" -c "mdw 0xE0042000 1" -c "resume" -c "shutdown" 2>&1
```

## Edge cases

- **连接失败 / 找不到 CMSIS-DAP**: 检查 USB 连接、确认调试器在设备管理器中可见（VID 1FC9 PID 5601）。CMSIS-DAP 应识别为 HID 设备，若被其他程序占用（如 Keil）需先关闭。
- **`target was in unknown state when halt was requested`**: init 后 target 可能未自动 halt。这是警告非错误，halt 请求会发出，后续操作通常仍可执行。若后续内存命令无输出，单独重跑该命令。
- **`not halted` / `context restore failed`**: 尝试 resume 一个未 halt 的 CPU 会报此错。确保命令链中先 `halt` 再 `resume`，或省略 resume。
- **烧录失败 `flash write error`**: 确认固件地址落在 Flash 区间（STM32F407: 0x08000000~0x080FFFFF），确认芯片未加读保护（`flash info 0` 查 protect 状态）。若已加保护需先 `stm32f2x unlock 0`。
- **SWD 连接不稳定**: 降低时钟速度，`-c "adapter speed 1000"` 或更低（500）。检查 SWDIO/SWCLK/GND 接线，目标板供电是否正常。
- **OpenOCD 版本不匹配 CPUTAPID**: 若芯片 IDCODE 与配置文件预期不符，可用 `-c "set CPUTAPID 0xXXXXXXXX"` 覆盖。

## References

- 命令速查见 `references/openocd-command-reference.md`
- OpenOCD 官方手册: http://openocd.org/doc/html/
- CMSIS-DAP 协议: https://arm-software.github.io/CMSIS-DAP/
