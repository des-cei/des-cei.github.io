---
title: "Recommendations"
permalink: /tools/impress/docs/recommendations

toc: true
toc_label: "Index"
toc_min_header: 2
toc_max_header: 5
toc_sticky: true
---

This document lists recommendations and possible issues that have to be taken into account when building reconfigurable systems with IMPRESS.

## Coarse- and medium-grain

* After downloading a reconfigurable module assert its reset signal.
* Source files must not contain spaces in their paths.
* It is recommended to use the partial reconfiguration decoupler IP when working with reconfigurable modules that use AXI interfaces. When it is not used, if some component access the AXI port while the reconfigurable module is being reconfigured the AXI port can stall.
* If the design is unroutable, it is better to avoid using the corner INT tiles for partition pin placement because these tiles can get saturated and they may lack routing resources to route all partition pins. This can be done by modifying the interface file
* When a reconfigurable module shares columns (in the same clock region) with distributed RAM and ROM memories or shift registers (implemented with memory LUTs) these components loose their run-time configuration when the reconfigurable module is downloaded into the FPGA. IMPRESS tries to implement all as these components using BRAM, however, this is not always possible (for example when you need to read immediately without any latency, as BRAMs need to wait one cycle before reading the data).

## Fine-grain

* When a reconfigurable module does not occupy whole columns of a clock region it is necessary to add *no_placement_pblocks* in the columns that contain fine-grain components to ensure that there cannot be static LUTs placed in the same clock region columns that have fine-grain components.
* Check that the components description and general fine-grain parameters are correct.
* When changing a fine-grain constant of less than 32 bits with *change_partition_constant* use a pointer to the new value. Do not pass the directly the integer. When the constant has more than 32 bit pass a pointer to an array.
