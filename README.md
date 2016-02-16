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
 |              | *** The two following folders contains the unmodified files ***
 + stm32_peripheral_libs | Git submodule for STM32 peripheral libraries. See: https://github.com/AdaCore/bareboard
```

####2. Requirements
```
The firmware is written in Ada 2012 and in SPARK 2014 and targets a STM32F4 chip, based on ARM.
Therefore, a compiler for ARM (ELF) is needed: The "GNAT GPL 2015" compiler for ARM (ELF) is one such compiler.
A recent GNAT Pro compiler for that target will also suffice.
```
