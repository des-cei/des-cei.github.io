---
title: "ARTICo³ Execution Model"
permalink: /tools/artico3/docs/model

toc: true
toc_label: "Index"
toc_min_header: 2
toc_max_header: 2
toc_sticky: true
---

## Kernel Execution

In ARTICo³, **kernels** are **computing-intensive** and **data-parallel sections of code** that are offloaded to a variable number of hardware accelerators.

Kernel execution in ARTICo³ relies on the concepts of **effective accelerator instance**, **local workload** and **global workload**.

* An **effective accelerator instance** is either **a single accelerator** without redundancy, **two accelerators in DMR** (Dual Modular Redundancy), or **three accelerators in TMR** (Triple Modular Redundancy)
* The **local workload** is the **amount of processing** an effective **accelerator** instance can perform
* The **global workload** is the **amount of processing** to be performed to finish the execution of a **kernel**

Depending on the **amount of effective accelerator instances** placed in the reconfigurable slots, the kernel will take **more or less time** to finish its **execution**.  **Workload scheduling** (i.e., parallelism management) is **transparently handled** by the ARTICo³ **runtime library**, as it can be seen in the following figure:

{:refdef: style="text-align: center;"}
![The ARTICo³ Execution Model](/assets/images/artico3/model.svg)
{: refdef}

:warning: **NOTE:** the white W and R letters inside black boxes represent data transfers to and from accelerators, respectively.


## Solution Space

In ARTICo³, **run-time adaptivity** is enabled by establishing user-driven **tradeoffs** between **computing performance**, **energy efficiency** and **fault tolerance**.

When working with ARTICo³, **changing the number of effective accelerator instances** using Dynamic and Partial Reconfiguration (DPR) not only **affects computing performance**, but also **energy efficiency**.

The following figure shows a block-based matrix multiplication (see the [Hello, World!](/tools/artico3/tutorials/matmul) tutorial) being performed in software and in ARTICo³ with 1, 2 or 4 accelerators working without hardware redundancy:

{:refdef: style="text-align: center;"}
![Hardware vs. Software](/assets/images/artico3/hw_sw.svg)
{: refdef}

:warning: **NOTE:** power traces have been measured in a [Pynq-Z1](http://www.pynq.io/){:target="_blank"} development board.

If the **embedded Voter Unit** of ARTICo³ is also used, an extra degree of freedom (i.e., **fault tolerance**) is added.  This enables the **full ARTICo³ solution space** for a given kernel, which is represented by a **family of curves** (fault tolerance) **in a 2D space** of execution time (computing performance) and energy consumption (energy efficiency).

The following figure shows the ARTICo³ solution space for an AES-256 cryptocore operating in CTR mode:

{:refdef: style="text-align: center;"}
![ARTICo³ Solution Space](/assets/images/artico3/space.svg)
{: refdef}

:warning: **NOTE:** measurements have been performed in a [KC705](https://www.xilinx.com/products/boards-and-kits/ek-k7-kc705-g.html){:target="_blank"} development board.
