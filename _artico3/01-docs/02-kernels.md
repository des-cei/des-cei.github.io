---
title: "ARTICo³ Kernel Specification"
permalink: /tools/artico3/docs/kernels

toc: true
toc_label: "Index"
toc_min_header: 2
toc_max_header: 2
toc_sticky: true
---

This is a guide to **develop ARTICo³ kernels** (hardware accelerators).  The ARTICo³ toolchain supports kernel specification using **low-level HDL descriptions** or **high-level C-based descriptions** to undergo HLS.


## ARTICo³ Wrapper

Either using HDL or C source code, the toolchain generates a VHDL entity that is connected to a **standard wrapper**.  This wrapper provides the user logic with a **configurable number of memory banks**, each one acting as a single port BRAM.  It also provides a **configurable number of R/W registers** that can be used for control/status purposes.  In addition, the wrapper provides a **data counter** that can be used from the user logic to know how many 32-bit data words have been written to the local memory banks.

{:refdef: style="text-align: center;"}
![ARTICo³ Kernel Wrapper](/assets/images/artico3/wrapper.svg)
{: refdef}

:warning: **NOTE:** given the way data are prepared and delivered to hardware accelerators, it is not recommended to use the data counter in the current implementation of ARTICo³, since it is highly likely to provide unexpected results.


## Kernel Memory Model

**Local memory banks** inside ARTICo³ hardware kernels can be used in **four different ways**:

* **Constant Memory** : ***input memory, common to all hardware accelerators of a given kernel, that remains constant throughout all kernel execution***.  It is meant to be set at the very beginning of the host application code, and it ***must not be changed after launching kernel execution*** unless proper deallocation/allocation is performed (see example code at the end of this section).

* **Input Memory** : ***input memory, used to store the data required for a given round during kernel execution***.  It is meant to be used as ***write-only memory from host*** application code and as ***read-only memory from kernel*** code.

* **InOut Memory** : ***bidirectional input/output memory***, used to store both the data required for a given round during kernel execution (before the accelerator starts processing) and the results produced after the same round during kernel execution (after the accelerator asserts its ready signal).  It is meant to be used as ***read/write memory from host*** application ***and kernel*** code.

* **Output Memory** : ***output memory, used to store the results produced after a given round during kernel execution***.  It is meant to be used as a ***read-only memory from host*** application code and as a ***write-only memory from kernel*** code.


The following diagram represents the **expected memory bank distribution**, from the runtime library point of view, in ARTICo³ kernels.  Any other specification would result in undefined behavior.

```
┌───────────────────────┐        ┬
│                       │ Write  │
│    Constant Memory    │ Once   │
│                       │        │
├───────────────────────┤        │
│                       │ Write  │
│     Input Memory      │ Always │  INPUTS (DMA send)
│                       │        │
├───────────────────────┤        │   ┬
│                       │ R/W    │   │
│     InOut Memory      │ Always │   │
│                       │        │   │
├───────────────────────┤        ┴   │ OUTPUTS (DMA receive)
│                       │ Read       │
│     Output Memory     │ Always     │
│                       │            │
└───────────────────────┘            ┴
```

:warning: **NOTE:** it is not mandatory to have all types of memory.  In fact, the **only requirement** is that the kernel has, **at least, one input memory port (either constant, input, or input/output)**.  Constant memory is written only once, usually in the first processing round of a kernel execution, but it is also triggered internally whenever a new copy of an accelerator is loaded and when the constant memory buffer is deallocated and allocated again (see example below).


### Example Code

:warning: **NOTE:** not all ARTICo³ functions are shown in the following code snippet.

```c
#define VALUES 1024
#define ROUNDS 256

// Allocate memory buffers
a3data_t *constant = artico3_alloc(VALUES * sizeof *constant, "kernel_i", "port0", A3_P_C);
a3data_t *input    = artico3_alloc(ROUNDS * VALUES * sizeof *input, "kernel_i", "port1", A3_P_I);
a3data_t *inout    = artico3_alloc(ROUNDS * VALUES * sizeof *inout, "kernel_i", "port2", A3_P_IO);
a3data_t *output   = artico3_alloc(ROUNDS * VALUES * sizeof *output, "kernel_i", "port3", A3_P_O);

// Initialize constant memory buffer
unsigned int i;
for (i = 0; i < VALUES; i++) constant[i] = i + 1;

// Initialize the rest of input memory buffers
for (i = 0; i < (ROUNDS * VALUES); i++) {
    input[i] = (i % VALUES) + 256;
    inout[i] = (i % VALUES) << 2;
}

// Launch kernel execution (constant memory buffer is written, changes
// from host code are forbidden)
artico3_kernel_execute("kernel_i", ROUNDS, 1);
artico3_kernel_wait("kernel_i");

// Constant memory deallocation
artico3_free("kernel_i", "port0");

// Constant memory reallocation (constant memory buffer can be modified
// from host code afterwards)
constant = artico3_alloc(1024 * sizeof *constant, "kernel_i", "port0", A3_P_C);

// Initialize constant memory buffer with different values
for (i = 0; i < 1024; i++) constant[i] = 2 * (i + 1);
```

:warning: **NOTE:** for HDL-based kernels, it is highly advisable to name the ports using "portX", where X corresponds to the index used in the top hardware module interface (see next section).


## HDL Kernel Specification

```vhdl
entity <kernel_name> is
    generic (
        C_DATA_WIDTH  : natural := 32; -- Data bus width (for ARTICo³ in Zynq, use 32 bits)
        C_ADDR_WIDTH  : natural := 16  -- Address bus width (for ARTICo³ in Zynq, use 16 bits)
    );
    port (
        -- Global signals
        clk           : in  std_logic;
        reset         : in  std_logic;
        -- Control signals
        start         : in  std_logic;
        ready         : out std_logic;
        -- Configuration registers
        reg_<i>_o_vld : out std_logic;
        reg_<i>_o     : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
        reg_<i>_i     : in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
        (...)
        -- Constant data memories (inputs)
        bram_<j>_clk  : out std_logic;
        bram_<j>_rst  : out std_logic;
        bram_<j>_en   : out std_logic;
        bram_<j>_we   : out std_logic;
        bram_<j>_addr : out std_logic_vector(C_ADDR_WIDTH-1 downto 0);
        bram_<j>_din  : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
        bram_<j>_dout : in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
        (...)
        -- Input data memories
        bram_<k>_clk  : out std_logic;
        bram_<k>_rst  : out std_logic;
        bram_<k>_en   : out std_logic;
        bram_<k>_we   : out std_logic;
        bram_<k>_addr : out std_logic_vector(C_ADDR_WIDTH-1 downto 0);
        bram_<k>_din  : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
        bram_<k>_dout : in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
        (...)
        -- Bidirectional I/O data memories
        bram_<l>_clk  : out std_logic;
        bram_<l>_rst  : out std_logic;
        bram_<l>_en   : out std_logic;
        bram_<l>_we   : out std_logic;
        bram_<l>_addr : out std_logic_vector(C_ADDR_WIDTH-1 downto 0);
        bram_<l>_din  : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
        bram_<l>_dout : in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
        (...)
        -- Output data memories
        bram_<m>_clk  : out std_logic;
        bram_<m>_rst  : out std_logic;
        bram_<m>_en   : out std_logic;
        bram_<m>_we   : out std_logic;
        bram_<m>_addr : out std_logic_vector(C_ADDR_WIDTH-1 downto 0);
        bram_<m>_din  : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
        bram_<m>_dout : in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
        (...)
        -- Data counter
        values        : in  std_logic_vector(31 downto 0)
    );
end <kernel_name>;
```

The **naming convention** for input/output register/memories is as follows:

* **Configuration registers** start at ```i = 0```
* **Constant input memories** start at ```j = 0```
* **Input memories** start at ```k = j + 1```, where ```j``` is the last constant input bank
* **Bidirectional I/O memories** start at ```l = k + 1```, where ```k``` is the last input bank
* **Output memories** start at ```m = l + 1```, where ```l``` is the last bidirectional I/O bank

:warning: **NOTE:** designers are expected to **organize their BRAM interfaces according to the memory model described in previous section** (from lower to higher index: constant memories, input ports, input/output ports, output ports).  Not following this recommendation would lead to unpredictable results and undefined behavior.

:warning: **NOTE:** the **timing of the START/READY pair** has to be the following:

```
        __    __    __    __    __    __    __    __    __    __    __
clk   _/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \_
                     _____                               _____
start ______________/     \_____________________________/     \_________
      ____________________             _______________________
ready                     \___________/                       \_________
```


## C-Based HLS Kernel Specification

```cpp
#include "artico3.h"
A3_KERNEL(a3reg_t   <reg_i>, (...),
          a3const_t <mem_j>, (...),
          a3in_t    <mem_k>, (...),
          a3inout_t <mem_l>, (...),
          a3out_t   <mem_m>, (...)) {
    (...)
}
```

It is important to identify **input and output** ports using the **flags**:

* ```a3reg_t``` for **configuration registers**
* ```a3const_t``` for **constant input memory ports**
* ```a3in_t``` for **input memory ports**
* ```a3inout_t``` for **bidirectional I/O memory ports**
* ```a3out_t``` for **output memory ports**

The **HLS** process **translates** these flags in:

```
a3reg_t   <reg_i> -> a3data_t *<reg_i>
a3const_t <mem_j> -> a3data_t <mem_j>[<size>]
a3in_t    <mem_k> -> a3data_t <mem_k>[<size>]
a3inout_t <mem_l> -> a3data_t <mem_l>[<size>]
a3out_t   <mem_m> -> a3data_t <mem_m>[<size>]
a3data_t          -> uint32_t
```

:warning: **NOTE:** the **ordering** of the ports is not important, the **toolchain automatically sets** and sorts everything.

:warning: **NOTE:** **registers need to be initialized** within kernel code.  It is advisable to do so right after kernel entry.

```cpp
A3_KERNEL(a3reg_t <reg_i>, ...) {
    a3reg_init(<reg_i>);
    (...)
}
```

:warning: **NOTE:** HLS-based accelerators require the addition of the ```artico3.h``` **header**.
