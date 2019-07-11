---
title: "ARTICo³ Project Structure"
permalink: /tools/artico3/docs/project

toc: true
toc_label: "Index"
toc_min_header: 2
toc_max_header: 3
toc_sticky: true
---

## Project Folder

ARTICo³ projects need to show the following structure:

    <project_name>
    |--- build.cfg
    |--- src
         |--- application
         |    |--- main.c
         |    |--- (...)
         |
         |--- a3_<kernel_0_name>
         |    |--- hls
         |    |    |--- <kernel_0_name>.cpp
         |    |    |--- (...)
         |    |
         |    |--- vhdl
         |    |    |--- <kernel_0_name>.vhd
         |    |    |--- (...)
         |    |
         |    |--- verilog
         |         |--- <kernel_0_name>.v
         |         |--- (...)
         |
         |--- (...)
         |
         |--- a3_<kernel_n_name>
              |--- hls
              |    |--- <kernel_n_name>.cpp
              |    |--- (...)
              |
              |--- vhdl
              |    |--- <kernel_n_name>.vhd
              |    |--- (...)
              |
              |--- verilog
                   |--- <kernel_n_name>.v
                   |--- (...)


## Configuration File

The file ```build.cfg``` contains all the required data to generate the target system.


### General Settings

Defined under the ```[General]``` section.  Its **fields** are:

* ```Name``` - name of your application

* ```TargetBoard``` - board to run your application on
    * ```pynq,c```
    * ```mmp,c```
    * ```zcu102,1```

* ```TargetPart``` - part to run you application on
    * ```xc7z020clg400-1```
    * ```xc7z100ffg900-2```
    * ```xczu9eg-ffvb1156-2-i```

* ```ReferenceDesign``` - reference design template
    * ```basic```

* ```TargetOS``` - operating system to use
    * ```linux```

* ```TargetXil``` - Xilinx tools to use
    * ```vivado,2017.1```

* ```CFlags``` - additional flags for compilation *\[OPTIONAL\]*

* ```LdFlags``` - additional flags for linking *\[OPTIONAL\]*

* ```LdLibs``` - additional libraries for linking *\[OPTIONAL\]*


### Kernel Settings

Defined under the ```[A3Kernel@<kernel_name>]``` sections.  There should be **one for each kernel** in the project.  Its **fields** are:

* ```HwSource``` - type of source code that should be used to generate the ARTICo³ accelerators
    * ```vhdl```
    * ```verilog```
    * ```hls```

* ```MemBytes``` - local memory storage size in Bytes (might be slightly increased to deal with bank partitioning, so that each memory bank contains an integer number of 32-bit words)
    * ```1 - 65536```

* ```MemBanks``` - number of memory banks to be generated (each one provides only one R/W access port from/to the user logic)

* ```Regs``` - number of Read/Write registers available in the kernel

* ```RstPol``` - reset polarity of user logic (not required for HLS-based kernels)
    * ```high```
    * ```low``` (default)

:warning: **NOTE:** ```MemBytes``` value is ORIENTATIVE, since the toolchain modifies it to get the closest (ceiling) value that renders a partitioning in which all banks (see next parameter) have an integer amount of 32-bit words (ARTICo³ data bus width).  Therefore, and since there is a 64kiB limitation (hardware addressing), users should not push the limit (use only the amount of memory required).

:warning: **NOTE:** in HLS-based cores, ```MemBanks``` equals the amount of I/O ports specified in the code
