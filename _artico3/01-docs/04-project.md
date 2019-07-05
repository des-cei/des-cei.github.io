---
title: "ARTICo³ Project Structure"
permalink: /tools/artico3/docs/project
---



```
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
     |         |--- <kernel_0_name>.vhd
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
               |--- <kernel_n_name>.vhd
               |--- (...)
```
