# Crazyflie 2.0 Firmware

This branch contains the source code for the full Ada + SPARK Crazyflie 2.0 firmware.
If you want to use the SPARK + C version, switch to the *crazyflie2* branch instead.

## Folder description
```
./                       | Root, contains the .gpr project file
 + Ada_Drivers_Library   | As submodule
 + crazyflie_support     | Support library
 |  + src                | Supprt code
 |  + test               | Some test code
 + src                   | Application code
```

## Git usage

This repository uses git submodules.

Clone with the `--recursive flag` to clone the submodules:
```
git clone --recursive https://github.com/AdaCore/Certyflie.git
```

To update, pull as normal, then update the submodules:
```
git pull
git submodule update --recursive
```

## Requirements

The firmware is written in Ada 2012 and in SPARK 2014 and targets an STM32F4 chip, based on ARM.
Therefore, a compiler for ARM (ELF) is needed: The "GNAT GPL 2017" compiler for ARM (ELF) is one such compiler.
A recent GNAT Pro compiler for that target will also suffice.

At this time, it's not possible to perform SPARK analysis (the 2016 version can't handle recent changes to Project files, and the 2017 version crashes).

## Building the firmware

The firmware uses a Ravenscar-Full runtime that targets STM32F4 boards. This runtime is included in the
"GNAT GPL 2016" for ARM (ELF) package and in the recent GNAT Pro packages for ARM.

To build the actual firmware, go on the project's root directory and type:
```
 gprbuild -P cf_ada_spark.gpr -p
```

## Flashing the firmware

The firmware can be flashed using the STM32F4 DFU mode.

First, install the *dfu-util* on your matchine. On Ubuntu:
```
apt-get install dfu-util
```

Then,

1. Plug the USB to micro-USB cable into your laptop
2. Disconnect the battery from your Crazyflie 2.0
3. Push in the power button on your Crazyflie 2.0. While continuing to hold in
the power button (this is the tricky part), plug the micro-USB connector end of
the cable into the Crazyflie.
4. Continue holding the power button for about five seconds since you plugged
the USB cable in). Watch the blue LED on the M2 arm until it displays a
secondary (faster) blink rate (flashes about once a second). Then you can
release the button.

With the STM32F4 in DFU mode, you should be able to find it with *lsusb*:
```
lsusb
...
Bus XXX Device XXX: ID 0483:df11 STMicroelectronics STM Device in DFU Mode
```

Create the BIN file from the ELF one with *objcopy* and then flash it using *dfu-util*:
```
arm-eabi-objcopy obj/cflie.elf -O binary obj/cflie.bin

sudo dfu-util -d 0483:df11 -a 0 -s 0x08000000 -D obj/cflie.bin
```
