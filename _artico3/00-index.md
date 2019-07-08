---
title: "ARTICo³"
permalink: /tools/artico3
---

{:refdef: style="text-align: center;"}
![](/assets/images/artico3/logo.svg)
{: refdef}

**ARTICo³** is an **open-source runtime reconfigurable processing architecture** to enable **hardware-accelerated** high-performance embedded computing.  It is highly flexible, offering **adaptive** computing **performance**, **energy efficiency**, and **fault tolerance** on demand.

{:refdef: style="text-align: center;"}
[See the brochure](/assets/files/artico3/artico3_brochure.pdf){:target="_blank"}
{: refdef}


## Framework Components

The ARTICo³ Framework provides three components to deploy reconfigurable and adaptive multi-accelerator systems:

* A hardware-based reconfigurable processing **architecture** -- ARTICo³
* An automated **toolchain** to implement multi-accelerator systems
* A **runtime** to manage FPGA reconfiguration and accelerator execution

![The ARTICo³ Framework](/assets/images/artico3/framework.svg)

The ARTICo³ architecture operates in a **processor-coprocessor approach**, where computationally intensive tasks are offloaded to one or several accelerators to **exploit** both **task-** and **data-level parallelism**.

{:refdef: style="text-align: center;"}
![The ARTICo³ Architecture](/assets/images/artico3/architecture.svg)
{: refdef}

Hence, the Framework takes as **inputs** the **host application code** and the **descriptions** of the **hardware accelerators**.  These descriptions can be provided as low-level **HDL code** -- VHDL and Verilog are supported -- or as high-level **C/C++ code** -- High-Level Synthesis (HLS) is used in this scenario.

Then, the Framework automatically composes and builds the multi-accelerator system, providing as **outputs** the **application binaries** and the **FPGA configuration files** (i.e., bitstreams).  It also **manages** all **Dynamic and Partial Reconfiguration** (DPR) processes, and **schedules** all **data-parallel processing** over the pool of instantiated **hardware accelerators** at run time.

Currently, the ARTICo³ Framework supports the following platforms:

* Xilinx Zynq-7000 SoC
* Xilinx Zynq UltraScale+ MPSoC


## Contact

If you are interested in the ARTICo³ Framework or if you want to request further information, do not hesitate to [contact us](mailto:alfonso.rodriguezm@upm.es,eduardo.delatorre@upm.es).  Technical issues should be handled via [GitHub Issues](https://github.com/des-cei/artico3/issues).
