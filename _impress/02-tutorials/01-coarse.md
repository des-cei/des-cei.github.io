---
title: "Coarse-grain reconfiguration tutorial"
permalink: /tools/impress/tutorials/coarse

toc: true
toc_label: "Index"
toc_min_header: 2
toc_max_header: 5
toc_sticky: true
---

This tutorial shows how to build a static system with one reconfigurable partition that can allocate three different reconfigurable modules (add, substract and multiply). The static system is composed of a VIO (virtual input output) IP connected to a reconfigurable partition with two 8-bit inputs and one 8-bit output. Thanks to the VIO component the user can test if the modules are being reconfigured properly.

**Requirements**

* Basic knowledge of Vivado and Xilinx SDK
* The tutorial is implemented in a xc7z020clg400-1 SoC. This tutorial can be followed almost entirely without having the device. The only limitation is that the user cannot test if the system is working correctly.

##  Static system project

Create a new project (in any path) and introduce the following commands in the Tcl console to generate the static system block design:

```
import_files -norecurse <path to IMPRESS>/examples/sources/coarse/design_time/static/reconf_part.vhd
source <path to IMPRESS>/examples/sources/coarse/design_time/static/static_coarse_and_medium.tcl
```

{:refdef: style="text-align: center;"}
![](/assets/images/impress/Tutorials/01-Coarse/static_bd.png)
{: refdef}

Generate the wrapper of the block design (right-click in the block design file -> Create HDL wrapper) and ensure that it is marked as the top source. Click the *Run Synthesis* button and wait until the synthesis step finishes. Open the synthesized design and write a design checkpoint inside the folder *\<path to IMPRESS\>/examples/sources/coarse/design_time/static/synth_checkpoint/static_system.dcp*

## Implementing the reconfigurable system with IMPRESS

Once the static files have been generated it is possible to use IMPRESS to generate the reconfigurable system. As explained in the documentation, IMPRESS needs three input files to build a reconfigurable system. The files to generate the static system and the reconfigurable modules are already filled in *\<path to IMPRESS\>/examples/coarse_grain/*.

The project_info file includes general information of the project and the location of the source files of the static system and the reconfigurable modules. The virtual_architecture file includes the coordinates of the reconfigurable partition. The interface file details how the static system and the reconfigurable partition interface to each other. Some important points are:
* **The partition_name in the virtual_architecture file must be the same as the reconfigurable partition name in the static system design**
* The ${local} variable represents the folder where the project_info file is stored.
* The location of a source file can be a folder or an individual files.
* In a coarse-grain reconfigurable systems, the static system and the reconfigurable modules share the same virtual architecture.

To use IMPRESS open a new Vivado window and introduce the following commands

```
source <path to IMPRESS>/design_time/reconfiguration_tool/impress.tcl
implement_reconfigurable_design <path to IMPRESS>/examples/coarse_grain/project_info
```

The first command sources IMPRESS API into Vivado. The second implements the system defined in the project_info file. This generates a folder called IMPRESS_build that contains synthesis & implementation checkpoints and the static and partial bitstreams.

There is also a folder called design_reconstruction that can be used to merge reconfigurable module into the static system at design-time. To see how this work open the checkpoint *\<path to IMPRESS\>/examples/coarse_grain/impress_build/DESIGN_RECONSTRUCTION/static_system.dcp* and then introduce the following command `insert_reconfigurable_module pblock_reconf_part_0 <path to IMPRESS>/examples/coarse_grain/impress_build/DESIGN_RECONSTRUCTION/group1_add.dcp` this will merge the add reconfigurable module inside the reconfigurable partition.
NOTE: The merging of a reconfigurable module can only be done if the reconfigurable region of the static system and the reconfigurable module are the same. Therefore, it cannot be used in medium-grain reconfigurable systems.

## Run-time management

Now we are going to design the software program in charge of downloading the partial bitstreams. First, open the Vivado project where we built the static system sources in the first section of this tutorial. In order to build the software it is necessary to export the hardware. To do so click *File->Export->Export Hardware->Ok* without marking the include bitstream option. Now click in *File->Launch SDK*.

Once in the SDK, create a new project by clicking *File->New->Application Project*. Name the project coarse, click next and select Empty application.

{:refdef: style="text-align: center;"}
![](/assets/images/impress/Tutorials/01-Coarse/new_project.png)
{: refdef}

We have to modify the system.mss in the BSP to include the generic fat file system library which allows using SD memory cards. Open the system.mss file and click *Modify this BSP's Settings* and select xilffs. In the xilffs tab change use_lfn to true to allow long names.

 {:refdef: style="text-align: center;"}
 ![](/assets/images/impress/Tutorials/01-Coarse/xilffs.png)
 {: refdef}

Now we have to import IMPRESS run_time source files to the SDK project. Import the files xc7z020 (.c and .h) and series7.h from *\<path to IMPRESS\>/run_time/FPGA_templates* and files IMPRESS_reconfiguration (.c and .h) and reconfig_pcap (.c and .h) from *<path to IMPRESS>/run_time/*. These files describe the FPGA layout and import IMPRESS run-time API. We also have to import files specific to this project stored in *\<path to IMPRESS\>/examples/sources/coarse/run_time/* which includes IMPRESS_reconfiguration_parameters (.c and .h), main.c and lscript. Below are some details of these files.

**IMPRESS_reconfiguration_parameters.h**

This file includes parameters that the user has to modify to describe the reconfigurable system. There are five important parameters relevant to coarse-grain reconfigurable systems.
* MAX_WIDTH_VIRTUAL_ARCHITECTURE , MAX_HEIGHT_VIRTUAL_ARCHITECTURE: These two parameters represent the size of the virtual architecture which is a matrix where each element is a reconfigurable region of the static system. In this case both are set to one because there is only one reconfigurable region.
* NUM_ELEMENTS: represents the number of different reconfigurable modules described in *IMPRESS_reconfiguration.c*. In this case there are three (add, subtract and multiply).
* INITIAL_ADDR_RAM: this memory address is used by IMPRESS to move a partial bitstream from the SD card to the memory RAM before downloading it to the FPGA. The user should modify the lscript file to ensure that the memory address from this point is free to use.
* FINE_GRAIN: set this variable to 0 if there aren't reconfigurable modules that use fine-grain components.

**IMPRESS_reconfiguration_parameters.c**

This file contains the *elements* variable that stores the information of each reconfigurable module. In coarse- and medium-grain reconfigurable systems each element only contains two fields:
* PBS_name: name of the partial bitstream stored in the FPGA
* size: width and height of the partial bitstream.

**lscript.ld**
 In this file it is necessary to reduce the amount of memory RAM that the program can use so that ps7_ddr_0 base address + size equals INITIAL_ADDR_RAM. Doing this we ensure that memory RAM from INITIAL_ADDR_RAM address is free to use to store partial bitstreams.

 **main.c**

 The main.c contains the steps needed to reconfigure modules in the static system. These are the important steps that are needed to reconfigure a system:
 * Declare a virtual_architecture_t variable.
 * Call *init_virtual_architecture()*.
 * Map each element of the virtual architecture variable to a region of the FPGA using *change_partition_position* function.
 * Start reconfiguring modules using *change_partition_element* function.

## Testing the system

Once the source files have been imported into the project we can test the system in the FPGA.

First connect the board (e.g., PYNQ or Zedboard) to the computer. Insert in the board an SD memory card with the partial bitstreams stored in *\<path to IMPRESS\>/examples/coarse_grain/impress_build/BITSTREAMS/*. Right-click in the project and select *debug as->debug configurations* select the last option (system debugger). In the bitstream field select browse and select the static bitstream stored in *\<path to IMPRESS\>/examples/coarse_grain/impress_build/BITSTREAMS/static.bit*. Check *reset entire system* and press Debug.

{:refdef: style="text-align: center;"}
![](/assets/images/impress/Tutorials/01-Coarse/debug_configuration.png)
{: refdef}

Press Step over (F6) until the ADD module is reconfigured. Now go to to the static system project and select *Open Target -> Auto Connect* in the flow navigator ribbon.

{:refdef: style="text-align: center;"}
![](/assets/images/impress/Tutorials/01-Coarse/open_target.png)
{: refdef}

Click the *Specify the probes (.ltx) file and refresh the device.* button and select the probes generated under the static bitstream folder in *\<path to IMPRESS\>/examples/coarse_grain/impress_build/BITSTREAMS/static_probes.ltx*
Add all the probes and give different values to probes vio_0_probe_out0 and vio_0_probe_out1. vio_0_probe_out2 is the reset signal of the reconfigurable module and its value should be 0. Check that the value of probe reconf_part_0_output1[7:0] is the sum of both values.

NOTE: in this tutorial it is not necessary to reset the module to ensure that the module works correctly but this may be the case in more complex reconfigurable modules

{:refdef: style="text-align: center;"}
![](/assets/images/impress/Tutorials/01-Coarse/VIO1.png)
{: refdef}

Then, click step over and check that probe reconf_part_0_output1[7:0] value is the substraction of both inputs. Do it again and check that now the value is the multiplication of both values.

