---
title: "ARTICo³ Reference Designs"
permalink: /tools/artico3/docs/templates

toc: true
toc_label: "Index"
toc_min_header: 2
toc_max_header: 2
toc_sticky: true
---

In the **ARTICo³ toolchain**, everything is **modular**.  There is a common core based upon Python scripts, but the rest is **highly configurable** using the so-called Reference Designs or **Templates**.


## Template Structure

The following files are contained in the **Reference Design for hardware project generation**:

    templates/ref_<os>_<board>_<revision>_<name>_vivado_<version>
    |--- pcores
    |    |--- artico3_shuffler_v1_00_a
    |    |    |--- (...)
    |    |
    |    |--- (...)
    |
    |--- artico3.cfg
    |--- build.tcl
    |--- clean.tcl
    |--- create_ip_library.tcl
    |--- export.tcl
    |--- <board>.xdc
    |--- (...)

* ```pcores```: custom IP cores

* ```artico3.cfg```: ARTICo³ configuration file (see next section)

* ```create_ip_library.tcl```: script to generate Xilinx IP Core definitions from a valid set of source files (i.e., ```.vhd``` for VHDL, ```.v``` for Verilog)

* ```export.tcl```: script to generate the Vivado IP Integrator project for the ARTICo³ setup

* ```build.tcl```: script to generate the bitstreams (full and partial) for the ARTICo³ setup

* ```clean.tcl```: script to clean the generated files in the Vivado IP Integrator project for the ARTICo³ setup

* ```<board>.xdc```: low-level FPGA constraints for the ARTICo³ setup (e.g., reconfigurable accelerators floorplan)

:warning: **NOTE:** the folder ```pcores``` contains the required custom IP blocks to be used in Vivado IP integrator.  The recommended approach is to generate symlinks to the elements in ```lib/pcores```.  In the previous hierarchy, the internal contents of the ```artico3_shuffler_v1_00_a``` folder have been removed for the sake of readability.


## ARTICo³ Configuration File

The file ```artico3.cfg``` contains the **ARTICo³ infrastructure configuration** in the ```[Shuffler]``` section.  Its **fields** are:

* ```Slots``` - number of reconfigurable slots available in this device

* ```PipeDepth``` - number of pipeline stages in the ARTICo³ infrastructure (between Shuffler and accelerators, used to avoid timing issues).

* ```ClkBuffer``` - type of hardware primitive to use as clock buffers
    * ```none``` (disables clock gating features)
    * ```global``` (use global FPGA buffers)
    * ```horizontal``` (use local buffers per clock region)

* ```RstBuffer``` - type of hardware primitive to use as reset buffers
    * ```none```
    * ```global``` (use global FPGA buffers)
    * ```horizontal``` (use local buffers per clock region)
