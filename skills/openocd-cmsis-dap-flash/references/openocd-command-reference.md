# OpenOCD 命令速查（CMSIS-DAP + STM32）

## 基础连接前缀

所有命令的基础前缀（`<CMDS>` 为实际操作命令）：

```
"D:\xpack-openocd-0.12.0-3\bin\openocd.exe" -s "D:\xpack-openocd-0.12.0-3\openocd\scripts" -f interface/cmsis-dap.cfg -c "transport select swd" -f target/stm32f4x.cfg -c "adapter speed 2000" -c "init" -c "<CMDS>" -c "shutdown" 2>&1
```

> 简记：`openocd -s <scripts> -f interface/cmsis-dap.cfg -c "transport select swd" -f target/<chip>.cfg -c "init" -c "<CMDS>" -c "shutdown"`

## 烧录

| 操作 | 命令 |
|------|------|
| 烧录 ELF（自动擦除+校验+复位） | `program app.elf verify reset exit` |
| 烧录 BIN（指定地址） | `program app.bin 0x08000000 verify reset exit` |
| 烧录 HEX | `program app.hex verify reset exit` |
| 仅烧录不校验 | `program app.elf reset exit` |
| 擦除地址范围 | `flash erase_address 0x08000000 0x10000` |
| 全片擦除（STM32F4） | `stm32f2x mass_erase 0` |
| 解除读保护 | `stm32f2x unlock 0` |

## CPU 控制

| 操作 | 命令 |
|------|------|
| 停止 | `halt` |
| 恢复 | `resume` |
| 复位并停止 | `reset halt` |
| 复位并运行 | `reset run` |
| 软复位 | `cortex_m reset_config sysresetreq`（配置）后 `reset` |

## 内存读写

| 操作 | 命令 |
|------|------|
| 读 32-bit × N | `mdw 0x08000000 4` |
| 读 16-bit × N | `mdh 0x1FFF7A22 1` |
| 读 8-bit × N | `mdb 0x40020010 8` |
| 写 32-bit | `mww 0x20000000 0xDEADBEEF` |
| 写 16-bit | `mwh 0x40020010 0x0001` |
| 写 8-bit | `mwb 0x40020014 0xFF` |
| 填充内存 | `mwb 0x20000000 0x00 256` |
| dump 到文件 | `dump_image flash.bin 0x08000000 0x100000` |
| 从文件加载到内存 | `load_image data.bin 0x20000000` |

## 寄存器

| 操作 | 命令 |
|------|------|
| 列出全部 | `reg` |
| 读指定寄存器 | `reg pc` / `reg sp` / `reg lr` |
| 写寄存器 | `reg r0 0x12345678` |

## 断点 / 单步

| 操作 | 命令 |
|------|------|
| 设断点 | `bp 0x08001000 2 hw` |
| 删断点 | `rbp 0x08001000` |
| 单步 | `step` |
| 继续运行 | `resume` |

## 芯片信息（STM32F407 常用地址）

| 信息 | 地址 | 命令 |
|------|------|------|
| DBGMCU_IDCODE | 0xE0042000 | `mdw 0xE0042000 1`（DEV_ID=0x413 即 F407）|
| Flash 容量 | 0x1FFF7A22 | `mdh 0x1FFF7A22 1`（单位 KB，F407ZG=1024）|
| UID（96-bit） | 0x1FFF7A10 | `mdw 0x1FFF7A10 3` |
| Flash 起始 | 0x08000000 | - |
| SRAM 起始 | 0x20000000 | - |
| CCM RAM | 0x10000000 | - |

## Flash 扇区布局（STM32F407，1MB）

| 扇区 | 偏移 | 大小 |
|------|------|------|
| 0-3 | 0x00000-0x0FFFF | 4 × 16KB |
| 4 | 0x10000-0x1FFFF | 64KB |
| 5-11 | 0x20000-0xFFFFF | 7 × 128KB |

## 调试速度建议

| 场景 | adapter speed |
|------|--------------|
| 正常 SWD | 2000（默认）|
| 连接不稳定 | 1000 |
| 排查信号问题 | 500 |
| reset 后（16MHz HSI）| 2000（配置文件自动降速）|

## GDB 联调

OpenOCD 启动后 GDB server 监听 3333 端口，另开终端：
```
arm-none-eabi-gdb app.elf
(gdb) target remote :3333
(gdb) monitor reset halt
(gdb) load
(gdb) break main
(gdb) continue
```
GDB 路径: `C:\Program Files (x86)\GNU Arm Embedded Toolchain\10 2021.10\bin\arm-none-eabi-gdb.exe`
