---
title: "Design-time documentation"
permalink: /tools/impress/docs/designtime

toc: true
toc_label: "Index"
toc_min_header: 2
toc_max_header: 5
toc_sticky: true
---

## Input Files

This section describes the input files that IMPRESS needs to build a reconfigurable system. These input files are:
  * project_info file
  * virtual_architecture file
  * interface file

There are templates of these files available in *\<path to IMPRESS\>/design_time/input_file_templates* that the user can fill to build a reconfigurable system. The contents of each file are shown below.

### project_info file

This project_info file contains the following fields:
  * Project variables
    * Directory
    : directory path where the project is built
    * Project name
    : name of the project folder
    * FPGA model
    : device where the system is implemented
    * IP repository
    : repositories needed for building the static system and the reconfigurable modules
  * Static system
    * Sources [^1] [^2]
    : path to a source file (or to a folder containing the source files) needed for building the static system
    * Virtual architecture
    : path of the virtual architecture file
  * Reconfigurable module sources
    * Reconfigurable module [^1]
      * Module name
      : this name is used in the partial bitstream name
      * Sources [^1] [^2]
      : path to a source file (or to a folder containing the source files) needed for building the reconfigurable module.
      * Partition group name [^1]
      : name of a partition group (i.e., relocatable partitions) where the reconfigurable module can be relocated
      * Virtual architecture
      : path of the virtual architecture file

### virtual_architecture file

This file contains the following fields:
  * Static system no placement pblocks
    * No placement pblock [^1]
    : defines a region where the static system resources cannot be placed. The region format is X<sub>0</sub>Y<sub>0</sub>:X<sub>f</sub>Y<sub>f</sub> (e.g., X2Y3:X7Y10)
  * Reconfigurable partition group [^1]
    * Partition group name
    : defines the name of a group of relocatable reconfigurable regions
    * Interface file
    : path to an interface file
    * Reconfigurable partition [^1]
      * Partition name
      :  name of the partition.
      * Hierarchical partition
      : This field describes if the current partition is located inside another partition
      * Pblock
      : Defines the reconfigurable region in the format X<sub>0</sub>Y<sub>0</sub>:X<sub>f</sub>Y<sub>f</sub> (e.g., X2Y3:X7Y10)

### interface file

This file contains the following fields:
  * Local nets
    * Pin name [^1]
    : Defines the interface for a net. To select an interface it is necessary to select which border is used (e.g., NORTH) and which tiles can be used (e.g., 3:5). Example netA SOUTH_3:7 means that netA can use interface nodes from tile 3 to 7.
  * Global nets
    * Pin name [^1]
    : Defines the interface for a global net. In this case instead of using a border we indicate which global resource is used. Valid resources go from 0 to 11. Example clk 0 means that net clk can use the global resource 0.


[^1]: This field can be added multiple times.
[^2]: Valid input sources are: vhdl, verilog, design checkpoints, block design, Vilinx constraints (xdc), xci, and edif. Block designs can be sourced in two formats: as a tcl script generated with write_bd_tcl or using the .bd file. It is necessary to specify the block design synthesis option as global to be sourced correctly.

## Output Files

IMPRESS generates the following folder structure

```
|
+---/bitstreams
|
|
+---/design_reconstruction
|
|
+---/error
|
|
+---/implemented
|
|
+---/synthesis
|
|
+---info

```

* The bitstream folder contains all the bitstreams that IMPRESS generates.
* The design reconstruction folder contains a design checkpoint of the static system and files needed to merge the static system with the reconfigurable modules in Vivado.
* The error folder only appears when a design has not been implemented correctly.
* The implemented folder contains design checkpoints of the static system and reconfigurable modules after the placement and routing.
* The synthesis folder contains design checkpoints of the static system and reconfigurable modules after the synthesis.
* The info file details the status of each design implementation.


## API

IMPRESS includes two functions that can be used:

* implement_reconfigurable_design: this function is used to build the reconfigurable system described in the project_info file
* insert_reconfigurable_module: is used to merge a reconfigurable module implementation with the static system

```
########################################################################################
# Function that is called to implement a reconfigurable design specified in the project
# info file.
#
# Argument Usage:
# project_info_file: path to the project info file
#
# Return Value:
########################################################################################
proc implement_reconfigurable_design {project_info_file}

########################################################################################
# To use this function it is necessary to open the static syatem DCP (design check point)
# saved in the DESIGN_RECONSTRUCTION folder if the project. Then it is posible
# reconstruct reconfigurable modules into the design checkpoint.
#
# Argument Usage:
# pblock_name: name of the pblock where the the reconfigurable module will be
# reconstructed.
# dcp_file: path of the reconfigurable module DCP included in the DESIGN_RECONSTRUCTION
# folder.
#
# Return Value:
########################################################################################
proc insert_reconfigurable_module {pblock_name dcp_file}
```

## Fine-grain components

There are three different types of fine-grain components (constants, multiplexors and functional units) that can be instantiated in a design. Each component has a set of parameters that allows IMPRESS to automatically place them in the desired location. It is important to know that, to speed-up fine-grain reconfiguration, IMPRESS always fills entire whole columns with a unique fine-grain component type (i.e., it does not mix different fine-grain  components). If a reconfigurable module with fine-grain components does not span a whole clock region, it is responsibility of the user to ensure that the whole clock-region column does not have regular LUTs that could be involuntarily reconfigured. If there are multiple reconfigurable modules stacked in the same clock region it is necessary to ensure that fine-grain columns are stacked in the same columns. The image below shows some possible cases. To avoid the static system from placing resources in columns that have fine-grain components it is possible to specify in the virtual architecture file regions that cannot be used to place components.

{:refdef: style="text-align: center;"}
![](/assets/images/impress/multiple_reconfigurable_modules.svg)
{: refdef}

### Constant

The fine-grain constant has the following properties:
* num_bits: number of bits of the constant.
* position: This variable is used by IMPRESS to automatically place fine-grain constants in a given order. For example if there are three constants with position values 1,2 and 3, the constant with position value 1 is placed first, then the constant with position value 2 and finally the constant with position value 3.
* constant_columns: this variable can be used to fix the number of columns reserved for constants. If this variable is set to 0 then IMPRESS uses the minimum number of columns. If it is set to any other variable, IMPRESS uses that number of columns.
* column_offset: this value represents in which column IMPRESS starts placing the components. When different fine-grain components have the same column_offset IMPRESS first places constants, then multiplexers and finally functional units. Multiple column_offset values are only required when one reconfigurable module has above or below itself multiple reconfigurable modules (as shown in the right part of the image).
* pblock: this is only used if the fine-grain component is going to be placed in the static system (instead of being placed inside a reconfigurable module).

### Multiplexer

The multiplexer has been implemented using vhdl 2008 and vhdl 93. The former one is easier to use but Vivado does not allow all vhdl 2008 characteristic and therefore it cannot be used in current Vivado versions.

The input of the multipler has a custom format *mux_input_t*. The function *vector_to_matrix_row(mux_input_t signal, input number, std_logic_vector signal)* can be used to connect the input of the multiplexer. See the fine-grain tutorial source files to see an example.

The fine-grain multiplexer has the following properties:
* num_inputs: number of multiplexer inputs
* data_width: data width of the inputs
* position: This variable is used by IMPRESS to automatically place fine-grain multiplexers in a given order. For example if there are three multiplexers with position values 1,2 and 3, the multiplexer with position value 1 is placed first, then the multiplexer with position value 2 and finally the multiplexer with position value 3.
* mux_columns: this variable can be used to fix the number of columns reserved for multiplexers. If this variable is set to 0 then IMPRESS uses the minimum number of columns. If it is set to any other variable, IMPRESS uses that number of columns.
* column_offset: this value represents in which column IMPRESS starts placing the components. When different fine-grain components have the same column_offset IMPRESS first places constants, then multiplexers and finally functional units. Multiple column_offset values are only required when one reconfigurable module has above or below itself multiple reconfigurable modules (as shown in the right part of the image).
* pblock : this is only used if the fine-grain component is going to be placed in the static system (instead of being placed inside a reconfigurable module).

### Functional Unit (FU)

* num_blocks_4_bits: the bit-width of functional units is a multiple of 4. For example if this parameter is set to 2, the functional unit will have 8 bits.
* position: This variable is used by IMPRESS to automatically place fine-grain FU in a given order. For example if there are three FU with position values 1,2 and 3, the FU with position value 1 is placed first, then the FU with position value 2 and finally the FU with position value 3.
* FU_columns:  this variable can be used to fix the number of columns reserved for FUs. If this variable is set to 0 then IMPRESS uses the minimum number of columns. If it is set to any other variable, IMPRESS uses that number of columns.
* column_offset: this value represents in which column IMPRESS starts placing the components. When different fine-grain components have the same column_offset IMPRESS first places constants, then multiplexers and finally functional units.
* pblock : this is only used if the fine-grain component is going to be placed in the static system (instead of being placed inside a reconfigurable module).
