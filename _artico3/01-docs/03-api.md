---
title: "ARTICo³ Runtime API"
permalink: /tools/artico3/docs/api

toc: true
toc_label: "Index"
toc_min_header: 2
toc_max_header: 3
toc_sticky: true
---

The ARTICo³ runtime API contains the basic function calls that need to be used by user applications to access the ARTICo³ infrastructure.


## Data Types

### ```a3data_t```

```c
/*
 * ARTICo³ data type
 *
 * This is the main data type to be used when creating buffers between
 * user applications and ARTICo³ hardware kernels. All variables to be
 * sent/received need to be declared as pointers to this type.
 *
 *     a3data_t *myconst  = artico3_alloc(size, kname, pname, A3_P_C);
 *     a3data_t *myinput  = artico3_alloc(size, kname, pname, A3_P_I);
 *     a3data_t *myoutput = artico3_alloc(size, kname, pname, A3_P_O);
 *     a3data_t *myinout  = artico3_alloc(size, kname, pname, A3_P_IO);
 *
 */
typedef uint32_t a3data_t;
```


### ```a3pdir_t```

```c
/*
 * ARTICo³ port direction
 *
 * A3_P_C  - ARTICo³ Constant Input Port
 * A3_P_I  - ARTICo³ Input Port
 * A3_P_O  - ARTICo³ Output Port
 * A3_P_IO - ARTICo³ Output Port
 *
 */
enum a3pdir_t {A3_P_C, A3_P_I, A3_P_O, A3_P_IO};
```


## Infrastructure

### ```artico3_init```

```c
/*
 * ARTICo³ init function
 *
 * This function sets up the basic software entities required to manage
 * the ARTICo³ low-level functionality (DMA transfers, kernel and slot
 * distributions, etc.).
 *
 * It also loads the FPGA with the initial bitstream (static system).
 *
 * Return : 0 on success, error code otherwise
 */
int artico3_init();
```


### ```artico3_exit```

```c
/*
 * ARTICo³ exit function
 *
 * This function cleans the software entities created by artico3_init().
 *
 */
void artico3_exit();
```


## Runtime Management

### ```artico3_load```

```c
/*
 * ARTICo³ load accelerator / change accelerator configuration
 *
 * This function loads a hardware accelerator and/or sets its specific
 * configuration.
 *
 * @name  : hardware kernel name
 * @slot  : reconfigurable slot in which the accelerator is to be loaded
 * @tmr   : TMR group ID (0x1-0xf)
 * @dmr   : DMR group ID (0x1-0xf)
 * @force : force reconfiguration even if the accelerator is already present
 *
 * Return : 0 on success, error code otherwise
 *
 */
int artico3_load(const char *name, size_t slot, uint8_t tmr, uint8_t dmr, uint8_t force);
```


### ```artico3_unload```

```c
/*
 * ARTICo³ remove accelerator
 *
 * This function removes a hardware accelerator from a reconfigurable slot.
 *
 * @slot  : reconfigurable slot from which the accelerator is to be removed
 *
 * Return : 0 on success, error code otherwise
 *
 */
int artico3_unload(size_t slot);
```


## Kernel Management

### ```artico3_kernel_create```

```c
/*
 * ARTICo³ create hardware kernel
 *
 * This function creates an ARTICo³ kernel in the current application.
 *
 * @name     : name of the hardware kernel to be created
 * @membytes : local memory size (in bytes) of the associated accelerator
 * @membanks : number of local memory banks in the associated accelerator
 * @regs     : number of read/write registers in the associated accelerator
 *
 * Return : 0 on success, error code otherwise
 *
 */
int artico3_kernel_create(const char *name, size_t membytes, size_t membanks, size_t regs);
```


### ```artico3_kernel_release```

```c
/*
 * ARTICo³ release hardware kernel
 *
 * This function deletes an ARTICo³ kernel in the current application.
 *
 * @name : name of the hardware kernel to be deleted
 *
 * Return : 0 on success, error code otherwise
 *
 */
int artico3_kernel_release(const char *name);
```


### ```artico3_kernel_execute```

```c
/*
 * ARTICo³ execute hardware kernel
 *
 * This function executes an ARTICo³ kernel in the current application.
 *
 * @name  : name of the hardware kernel to execute
 * @gsize : global work size (total amount of work to be done)
 * @lsize : local work size (work that can be done by one accelerator)
 *
 * Return : 0 on success, error code otherwisw
 *
 */
int artico3_kernel_execute(const char *name, size_t gsize, size_t lsize);
```


### ```artico3_kernel_wait```

```c
/*
 * ARTICo³ wait for kernel completion
 *
 * This function waits until the kernel has finished.
 *
 * @name : hardware kernel to wait for
 *
 * Return : 0 on success, error code otherwise
 *
 */
int artico3_kernel_wait(const char *name);
```


### ```artico3_kernel_reset```

```c
/*
 * ARTICo³ reset hardware kernel
 *
 * This function resets all hardware accelerators of a given kernel.
 *
 * @name : hardware kernel to reset
 *
 * Return : 0 on success, error code otherwise
 *
 */
int artico3_kernel_reset(const char *name);
```


### ```artico3_kernel_wcfg```

```c
/*
 * ARTICo³ configuration register write
 *
 * This function writes configuration data to ARTICo³ kernel registers.
 *
 * @name   : hardware kernel to be addressed
 * @offset : memory offset of the register to be accessed
 * @cfg    : array of configuration words to be written, one per
 *           equivalent accelerator
 *
 * Return : 0 on success, error code otherwise
 *
 * NOTE : configuration registers need to be handled taking into account
 *        execution priorities.
 *
 *        TMR == (0x1-0xf) > DMR == (0x1-0xf) > Simplex (TMR == 0 && DMR == 0)
 *
 *        The way in which the hardware infrastructure has been implemented
 *        sequences first TMR transactions (in ascending group order), then
 *        DMR transactions (in ascending group order) and finally, Simplex
 *        transactions.
 *
 */
int artico3_kernel_wcfg(const char *name, uint16_t offset, a3data_t *cfg);
```


### ```artico3_kernel_rcfg```

```c
/*
 * ARTICo³ configuration register read
 *
 * This function reads configuration data from ARTICo³ kernel registers.
 *
 * @name   : hardware kernel to be addressed
 * @offset : memory offset of the register to be accessed
 * @cfg    : array of configuration words to be read, one per
 *           equivalent accelerator
 *
 * Return : 0 on success, error code otherwise
 *
 * NOTE : configuration registers need to be handled taking into account
 *        execution priorities.
 *
 *        TMR == (0x1-0xf) > DMR == (0x1-0xf) > Simplex (TMR == 0 && DMR == 0)
 *
 *        The way in which the hardware infrastructure has been implemented
 *        sequences first TMR transactions (in ascending group order), then
 *        DMR transactions (in ascending group order) and finally, Simplex
 *        transactions.
 *
 */
int artico3_kernel_rcfg(const char *name, uint16_t offset, a3data_t *cfg);
```


## Memory Management

### ```artico3_alloc```

```c
/*
 * ARTICo³ allocate buffer memory
 *
 * This function allocates dynamic memory to be used as a buffer between
 * the application and the local memories in the hardware kernels.
 *
 * @size  : amount of memory (in bytes) to be allocated for the buffer
 * @kname : hardware kernel name to associate this buffer with
 * @pname : port name to associate this buffer with
 * @dir   : data direction of the port
 *
 * Return : pointer to allocated memory on success, NULL otherwise
 *
 */
void *artico3_alloc(size_t size, const char *kname, const char *pname, enum a3pdir_t dir);
```


### ```artico3_free```

```c
/*
 * ARTICo³ release buffer memory
 *
 * This function frees dynamic memory allocated as a buffer between the
 * application and the hardware kernel.
 *
 * @kname : hardware kernel name this buffer is associanted with
 * @pname : port name this buffer is associated with
 *
 * Return : 0 on success, error code otherwise
 *
 */
int artico3_free(const char *kname, const char *pname);
```


## Data Reinterpretation

### ```ftoa3```

```c
/*
 * ARTICo³ data reinterpretation: float to a3data_t (32 bits)
 *
 */
static inline a3data_t ftoa3(float f) {
    union { float f; a3data_t u; } un;
    un.f = f;
    return un.u;
}
```


### ```a3tof```

```c
/*
 * ARTICo³ data reinterpretation: a3data_t to float (32 bits)
 *
 */
static inline float a3tof(a3data_t u) {
    union { float f; a3data_t u; } un;
    un.u = u;
    return un.f;
}
```


## Monitoring (PMCs)

### ```artico3_hw_get_pmc_cycles```

```c
/*
 * ARTICo³ low-level hardware function
 *
 * Reads the value of the "cycles" PMC.
 *
 * @slot : number/ID of the slot that is to be checked
 *
 * Return : PMC value (execution cycles)
 *
 */
uint32_t artico3_hw_get_pmc_cycles(uint8_t slot);
```


### ```artico3_hw_get_pmc_errors```

```c
/*
 * ARTICo³ low-level hardware function
 *
 * Reads the value of the "errors" PMC.
 *
 * @slot : number/ID of the slot that is to be checked
 *
 * Return : PMC value (execution errors)
 *
 */
uint32_t artico3_hw_get_pmc_errors(uint8_t slot);
```
