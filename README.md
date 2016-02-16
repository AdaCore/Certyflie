#Crazyflie 2.0 Firmware

This branch contains the source code for the full Ada + SPARK Crazyflie 2.0 firmware.

####1. Folder description
```
./                       | Root, contains the .gpr project file
 + init                  | Contains the main unit
 + config                | Configuration files
 + drivers               | Hardware driver layer
 |  + body               | Drivers packages implementation
 |  + spec               | Drivers packages interface. Interface with the HAL
 + hal                   | Hardware abstaction layer
 |  + body               | HAL packages implementation
 |  + spec               | HAL packages specification. Interface with the modules
 + modules               | Firmware operating code
 |  + body               | Firmware tasks and implementation of the functional modules (e.g: stabilization)
 |  + spec               | Firmware tasks and specification of the functional modules
 + utils                 | Utils code. Implementation of utility packages (e.g: filtering).
 |  + body               | Utils packages implementation
 |  + spec               | Utils packages specification. Used by other parts of the firmware (e.g: modules, HAL)
 + types
 |  + spec               | Contains type definitions that are shared with several firmware parts
 + stm32_peripheral_libs | Git submodule for STM32 peripheral libraries. See: https://github.com/AdaCore/bareboard
```

####2. Requirements

The firmware is written in Ada 2012 and in SPARK 2014 and targets a STM32F4 chip, based on ARM.
Therefore, a compiler for ARM (ELF) is needed: The "GNAT GPL 2015" compiler for ARM (ELF) is one such compiler.
A recent GNAT Pro compiler for that target will also suffice.

To be able to analyze the SPARK code, you will need the SPARK toolsuite (e.g: "SPARK GPL 2015").

####3. Building the firmware

The firmware uses a SFP Ravenscar runtime that targets STM32F4 boards. This runtime is included in the
"GNAT GPL 2015" for ARM (ELF) package and in the recent GNAT Pro packages for ARM.
However, the firmware needs some mathematical functions that are not included in this runtime by default.

Therefore, to be able to build the actual firmware, you will need to recompile the runtime with
the needed files. These files can be found in the Ravenscar Full runtime targetting STM32F4 boards
install directory.

If you use the "GNAT GPL 2015" ARM compiler, you can do it following these simple steps:

Copy the needed files:
```
cd $(INSTALL_DIR)/arm-eabi/lib/gnat

cp ./ravenscar-full-stm32f4/math/* ./ravenscar-sfp-stm32f4/math
```
Rebuild the runtime:
```
cd ravenscar-sfp-stm32f4

gprbuild --target=arm-eabi -P runtime_build.gpr
```

Once you modified and rebuilt the runtime, you will be able to build the actual firmware.
To do it, go on the project's root directory and type:
```
 gprbuild -P cf_ada_spark.gpr -p
```

####4. Flashing the firmware

The firmware can be flashed using the STM32f4 DFU mode.

First, install the *dfu-util* on your matchine. On Ubuntu:
```
apt-get install dfu-util
```

Then, set the Crazyflie's STM32F4 in DFU mode by holding down the reset button
for about 5 seconds, until you see the blue led blinking in a fastest way.

With the STM32F4 in DFU mode, you should be able to find it with *lsusb*:
```
lsusb
...
Bus XXX Device XXX: ID 0483:df11 STMicroelectronics STM Device in DFU Mode
```

Create the BIN file from the ELF one with *objcopy* and then flash it using *dfu-util*:
```
arm-eabi-objcopy obj/cflie.elf -O binary obj/cflie.bin

sudo dfu-util -d 0483:df11 -a 0 -s 0x08000000 -D cflie.bin
```
