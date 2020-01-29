---
title: "Run-time documentation"
permalink: /tools/impress/docs/runtime

toc: true
toc_label: "Index"
toc_min_header: 2
toc_max_header: 5
toc_sticky: true
---

## Run-time library files

The run-time library includes the following files:
*  *IMPRESS_reconfiguration .c and .h* files include high-level functions to manage multi-grain reconfigurable systems
* *reconfig_pcap .c and .h* files are the PCAP reconfiguration port drivers
* *IMPRESS_reconfiguration_parameters .c and .h* files describe the reconfigurable system.
*  *\<device_model\> .c and .h* and *series7.h* describe the fpga fabric layout

The following sections describe how the user has to use these files to build a reconfigurable system.

### reconfigurable system description

*IMPRESS_reconfiguration .c and .h* files must be filled by the user to describe the reconfigurable system.

*IMPRESS_reconfiguration.c* has an array variable called *elements* that describes all the reconfigurable modules and their properties. Each reconfigurable module has the following properties:

```
typedef struct {
  #if FINE_GRAIN
    int num_constants;
    int num_bits_in_constant[MAX_CONSTANTS];
    int constant_column_offset[MAX_CONSTANTS];
    int num_constant_columns[MAX_CONSTANTS];
    int num_muxes;
    int mux_data_width[MAX_MUXES];
    int mux_num_inputs[MAX_MUXES];
    int mux_column_offset[MAX_MUXES];
    int num_mux_columns[MAX_MUXES];
    int num_FU;
    int FU_4_bit_blocks[MAX_FU];
    int FU_column_offset[MAX_FU];
    int num_FU_columns[MAX_FU];
    int num_blocks;
    int offset_blocks[MAX_COLUMN_OFFSETS];
  #endif
  char PBS_name[MAX_CHARS_PER_PBS]; // Contains the name of the PBS wich represents the element
  int size[2]; //Width, Height
} element_info_t;
```
All the fields should be initialized by the user except *num_blocks* and *offset_blocks* that are automatically calculated by IMPRESS.

* Size: is the width and height of the reconfigurable module
* PBS_name: is the name of the partial bitstream stored in the SD memory card.
* Fine-grain parameters: represents the info of the fine-grain components. They should match the values given to the fine-grain components (see design_time document). For example, num_bits_in_constant[MAX_CONSTANTS] is an array that specifies the number of bits of each constant starting from the constant with the lower position number. If the reconfigurable module does not have fine-grain components leave this field uninitialized

NOTE: an element usually represent a reconfigruable module but it can also represent a static region with fine-grain component. In this case PBS_name can be left uninitialized.

*IMPRESS_reconfiguration.h* is a set of parameters that is used by IMPRESS to fix the size of variables. These variables are:

* MAX_WIDTH_VIRTUAL_ARCHITECTURE , MAX_HEIGHT_VIRTUAL_ARCHITECTURE: These two parameters represent the size of the virtual architecture which is a matrix where each element is a reconfigurable region of the static system.
* NUM_ELEMENTS: represents the number of different reconfigurable modules described in *IMPRESS_reconfiguration.c*
* INITIAL_ADDR_RAM: this memory address is used by IMPRESS to move a partial bitstream from the SD card to the memory RAM before downloading it to the FPGA. The user should modify the lscript file to ensure that the memory address from this point is free to use.
** fine-grain parameters **
* MAX_CONSTANTS: represents the maximum number of constants that one element can have.
* MAX_MUXES: represents the maximum number of multiplexers that one element can have.
* MAX_FU: represents the maximum number of FUs that one element can have.
* MAX_BITS_PER_CONSTANT: represents the maximum number of bits a constant can have.
* MAX_COLUMNS_CONSTANTS: represents the maximum number of columns that are reserved for constants in an element.
* MAX_COLUMNS_MUX: represents the maximum number of columns that are reserved for multiplexers in an element.
* MAX_COLUMNS_FU: represents the maximum number of columns that are reserved for functional units in an element.
* MAX_COLUMN_OFFSETS: represents the maximum number of different column offsets in an element.


### FPGA template

This file describes the FPGA layout. It has two variables fpga and fpga_bram. The fpga is a matrix that describe each column from the down-left corner of the FPGA. Each column has the following format {block(top/bottom, row address, number of frames), resource type}. As explained in series 7 Configuration Guide (UG470), the top/bottom describe the location of the row while the row addresses increment from center to top and then reset and increment from center to bottom. The fpga_bram describes if the column is a BRAM and the relative number of the BRAM using the following format content(bram content, relative position).
See xc7z020.c located at *\<path to IMPRESS\>/run_time/FPGA_templates/* to see an example.


### run-time API

This section shows the variables and functions that can be used to manage reconfigurable systems at run-time. The following variables and functions in *IMPRESS_reconfiguration.h* can be used to download coarse- and medium-grain reconfigurable systems. See the tutorials to see examples of how these functions can be used.

**Types**

virtual_architecture_t: this variable is a matrix of size *MAX_WIDTH_VIRTUAL_ARCHITECTURExMAX_HEIGHT_VIRTUAL_ARCHITECTURE* where each element represents a position of the FPGA (the position can be changed at run-time) where a reconfigurable module can be allocated.

**Functions**
```
/****************************************************************************/
/**
*
* Initializes all the components and variables needed to use multi-grain
* reconfiguration
*
* @return   none
*
*****************************************************************************/
void init_virtual_architecture();
/****************************************************************************/
/**
*
* The virtual architecture variable is a matrix where each element represents
* a region that can allocate a reconfigurable module. This function maps a
* matrix element with coordinates of an FPGA.
*
* @param virtual_architecture:
* @param x: x coordinate of the virtual architecture matrix
* @param y: y coordinate of the virtual architecture matrix
* @param position_x: x FPGA coordinate
* @param position_y: x FPGA coordinate
* @return   none
*
*****************************************************************************/
void change_partition_position(virtual_architecture_t *virtual_architecture, int x, int y, int position_x, int position_y);
/****************************************************************************/
/**
*
* Once the virtual architecture matrix is mapped to specific FPGA coordinates,
* it is possible to start downloading reconfigurable modules. The
* reconfigurable modules that can be used must be described by the user in the
* elements variable located at IMPRESS_reconfiguration_parameters.c file. The
* module is reconfigurated placing the left down corner of the module at the
* FPGA location stored in the virtual architecture variable
*
* @param virtual_architecture:
* @param x: x coordinate of the virtual architecture matrix
* @param y: y coordinate of the virtual architecture matrix
* @param num_element: reconfigurable module position in elements variable
*
* @return  XST_SUCCESS or XST_FAILURE if the reconfigurable module could
*           not be reconfigured correctly
*
*****************************************************************************/
int change_partition_element(virtual_architecture_t *virtual_architecture, int x, int y, int num_element);
```

IMPRESS also includes functions to manage fine-grain reconfiguration at run-time. The following functions can be used to manage fine-grain reconfigurable systems.

```
/****************************************************************************/
/**
*
* This function is similar to change_partition_element but it does not
* reconfigure an element. Its purpose is to indicate that in that region there
* is a static region with fine-grain components.
*
* @param virtual_architecture:
* @param x: x coordinate of the virtual architecture matrix
* @param y: y coordinate of the virtual architecture matrix
* @param num_element: reconfigurable module position in elements variable
*
* @return   none
*
*****************************************************************************/
void add_fine_grain_static_region(virtual_architecture_t *virtual_architecture, int x, int y, int element_info);
/****************************************************************************/
/**
*
* This function can be used to change the value of a fine-grain constant of an
* element of the virtual architecture.
* IMPORTANT: this function only reconfigures the internal frames representation
* variables. The FPGA is not reconfigured until reconfigure_fine_grain() is
* called.
*
* @param virtual_architecture:
* @param x: x coordinate of the virtual architecture matrix
* @param y: y coordinate of the virtual architecture matrix
* @param constant_number: position of the constant to change as represented in
* the element variable
* @param value[MAX_WORDS_PER_CONSTANT] pointer to a vector that contains the
*        new value of the constant. If the constant has 32 or less bits, this
*        variable is a pointer to an uint32_t variable.
* @return   none
*
*****************************************************************************/
void change_partition_constant(virtual_architecture_t *virtual_architecture, int x, int y, int constant_number, uint32_t value[MAX_WORDS_PER_CONSTANT]);
/****************************************************************************/
/**
*
* This function can be used to change the value of a fine-grain multiplexor of an
* element of the virtual architecture.
* IMPORTANT: this function only reconfigures the internal frames representation
* variables. The FPGA is not reconfigured until reconfigure_fine_grain() is
* called.
*
* @param virtual_architecture:
* @param x: x coordinate of the virtual architecture matrix
* @param y: y coordinate of the virtual architecture matrix
* @param mux_number: position of the multiplexor to change as represented in
* the element variable
* @param value: input that will be selected
* @return   none
*
*****************************************************************************/
void change_partition_mux(virtual_architecture_t *virtual_architecture, int x, int y, int mux_number, int value);
/****************************************************************************/
/**
*
* This function can be used to change the value of a fine-grain FU of an
* element of the virtual architecture.
* IMPORTANT: this function only reconfigures the internal frames representation
* variables. The FPGA is not reconfigured until reconfigure_fine_grain() is
* called.
*
* @param virtual_architecture:
* @param x: x coordinate of the virtual architecture matrix
* @param y: y coordinate of the virtual architecture matrix
* @param FU_number: position of the FU to change as represented in
* the element variable
* @param value: new functionality of the FU
* @return   none
*
*****************************************************************************/
void change_partition_FU(virtual_architecture_t *virtual_architecture, int x, int y, int FU_number, FU_functions_t value);
/****************************************************************************/
/**
*
* It starts the fine-grain reconfiguration of all the fine-grain components
* that have been updated.
*
* @return   none
*
*****************************************************************************/
void reconfigure_fine_grain();
```

