---
title: Barrelfish与seL4对Capability支持的详细对比
tags: 
	- Barrelfish 
	- seL4 
	- 操作系统
	- Capability
categories:
	- Barrelfish
---

# 概述

Barrelfish采用Capability机制对系统资源进行管理，该机制源自seL4。

Capability可以看做是访问系统中各种资源的令牌。内存空间、IO端口、进程控制块（PCB），中断号，进程通信的信道等，都可以通过Capability来管理。

内核通常会在内核空间维护每个进程所持有的Capability的详细数据，而用户进程持有Capability的引用。当用户程序访问系统资源时，需要使用该资源对应的Capability的引用调用系统调用，内核检查该引用的合法性后，才会允许用户对该资源进行操作。

## Capability的类型
Capability的类型通常与资源一一对应。
- 对于内存区域，内核中的Capability可以表示如下。

```c
struct PhysAddr_Cap {
	enum objtype_t type = PHYS_ADDR;
	addr_t base;                     // 内存基地址
	int bytes;                       // 字节数
};
```

- 对于PCB，内核中的Capability可以表示如下。

```c
struct pcb {
	pid_t pid;
	pid_t parent;
	register_t regs[];
	enum state_t state;
	...
	//进程控制块的其他内容
};
struct PCB_Cap {
	enum objtype_t type = PCB;
	struct pcb *pcb;
};
```

- 对于IRQ中断号管理，内核可以使用如下Capability

```c
struct IRQSrc_Cap {
	enum objtype_t type = IRQSrc;
	//表示一个中断号的区间
	int irq_start;
	int irq_end;
};
```

- 对于通信信道，内核可以使用如下Capability

```c
struct EndPoint_Cap {
	enum objtype_t type = EndPoint;
	struct pcb* receiver;           // 接收进程
	char* buffer;			
	size_t buffer_size;
};
```

- 还有些资源对应的Capability，可能不需要额外的信息存储

```c
struct [IPI, Null, IRQTable] { //分别表示核间终端(Inter Processor Interrupt)和空
	enum objtype_t type = ...;
};
```

## Capability的类型转换
_ 关键字：Capability类型 Capability关系数据库 _

从上节中介绍的类型中可以看出，计算机内的各种资源是有层次关系的。
内存空间是最基础的一种资源，PCB、EndPoint等，都是由内存空间转换而来的。Capability的类型转换就是为了模拟这种资源的层次关系。当用户程序取得一种Capability时（通常是表示一段内存空间的RAM Capability），可以使用系统调用将该Capability转换为其他类型，内核首先通过事先定义好的规则验证该转换是否合法，若合法，则会在内核空间为该进程创建一个目标类型的Capability，并把引用返回给用户程序。
类型的转换并不会导致一个Capability的删除，内核会维护新产生的Capability与源Capability间继承的关系，若用户空间重复对一个的Capability进行类型转换操作，那么内核会拒绝该操作。
基于Capability的内核利用Capability的类型转换来实现普通操作系统提供的系统调用。
比如，若用户空间的程序需要申请一个IRQ号，那么它需要持有IRQTable_Cap（表明具有操作内核中IRQ转发表的权限），然后使用类似于如下的系统调用。
```plain
An_IRQSrc_Cap_Ref = cap_retype(An_IRQTable_Cap_Ref, irq_num_from, irq_num_to, irq_handler_pointer);
```
操作系统会进行如下几步操作。
1. 验证程序提供的Capability Reference是否正确。
2. 在用户进程的PCB中新建一个IRQSrc类型的Capability，并根据参数填写内核中的IRQ转发表。
3. 在Capability关系数据库中，记录IRQSrc_Cap和IRQTable_Cap之间的转换关系。
4. 把新产生的IRQSrc_Cap的引用返回给用户程序。

其他诸如映射页表(Ram_Cap -> Frame_Cap)，创建进程间通信信道（Ram_Cap -> EndPoint_Cap)等操作都有类似的过程。

## Capability的其他操作

1. 撤销（revoke）

	可以禁止目标进程使用某项资源。如撤销IRQSrc可导致用户进程不再处理某些IRQ。对Frame_Cap的撤销可以导致页表映射项的删除。

2. 复制（copy）

	利用复制可以是一个进程把他拥有的一些权限继承给它的子进程。

# 对比

要对比Capability功能，可以从__Capability类型数量__和支持的__Capability操作__两方面来对比。


## Capability类型对比

| fdsljakj| sun       | fdsal    |
| -         | -        |
| flkdsjal  | fdlksajf |
| flkdsajfl | fjkldsja |

/*
 * Copyright (c) 2009, 2010, 2012, 2015, 2016, ETH Zurich.
 * Copyright (c) 2015, 2016 Hewlett Packard Enterprise Development LP.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE file.
 * If you do not find this file, copies can be found by writing to:
 * ETH Zurich D-INFK, Universitaetstr. 6, CH-8092 Zurich. Attn: Systems Group.
 */

/**
    Hamlet input file.

    This file defines the Barrelfish capability type system.

    (Meta-)Comments about the syntax are enclosed between /** ... **/
    Comments of the Hamlet language are enclosed between /* ... */
**/

/** We can define some constants using the "define" construct **/

/* XXX: these must match the corresponding OBJBITS definitions in
 * barrelfish_kpi/capabilities.h */

/* Size of L2 CNode: L2 resolves 8 bits of Cap address space */
define objsize_l2cnode 16384;
/* Size of DCB: */
define objsize_dispatcher 1024;
/* Size of (x86_64) VNode: */
define objsize_vnode 4096; /* BASE_PAGE_SIZE */
/* Size of ARMv7 VNodes */
define objsize_vnode_arm_l1 16384;
define objsize_vnode_arm_l2 1024;
/* size of a kernel control block */
define objsize_kcb 65536; /* OBJSIZE_KCB */
/* size of a mapping cap:
 * if mappings are zero-sized they mess up range queries */
define objsize_mapping 1;

/**
    The capabilities of the whole system are listed thereafter.
    The minimal definition consists of a name and an empty body.
**/

cap Null is_never_copy {
    /* Null/invalid object type */
};

cap Memory abstract {
    /**
      For a populated cap, we need to give the type and name of each
      of its fields, such as:
      "genpaddr base;" for instance

      In order to implement various comparisons, we need to specify a address
      and size for each type that is backed by memory. The size may be
      specified directly with "size" or as "size_bits".

      Additional equality fields can be specified with an "eq" prefix, as in
      "eq genpaddr base;"
    **/

    address genpaddr base;  /* Physical base address of Memory object */
    pasid pasid;            /* Physical Address Space ID */
    size gensize bytes;     /* Size of region in bytes */
};



/* Physical address range (root of cap tree) */
cap PhysAddr from_self inherit Memory;

cap Mapping abstract {
    "struct capability" cap;
    eq lvaddr pte;
    uint32 offset;
    uint16 pte_count;

    address { get_address(cap) };
    size { objsize_mapping };
};

cap VNode abstract {
    address genpaddr base;  /* Base address of VNode */
    size { objsize_vnode };
};

/** The following caps are similar to the previous one **/

/* RAM memory object */
cap RAM from PhysAddr from_self inherit Memory;

/* Abstract CNode, need to define size */
cap CNode abstract {
    address lpaddr cnode;               /* Base address of CNode */
    caprights rightsmask;               /* Cap access rights */
};

/* Level 1 CNode table, resizable */
cap L1CNode from RAM inherit CNode {
    size gensize allocated_bytes;       /* Allocated size of L1 CNode in bytes */
};

/* Level 2 CNode table, resolves 8 bits of cap address */
cap L2CNode from RAM inherit CNode {
    size { objsize_l2cnode };                 /* Size of L2 CNode in bytes (16kB) */
};

cap FCNode {
     /* Foreign CNode capability */

     eq genpaddr cnode;	    /* Base address of CNode */
     eq uint8 bits;    	    /* Number of bits this CNode resolves */
     caprights rightsmask;
     eq coreid core_id;     /* The core the cap is local on */
     uint8 guard_size; 	    /* Number of bits in guard */
     caddr guard;           /* Bitmask already resolved when reaching this CNode */
};

/** Dispatcher is interesting is several ways. **/

/**
  XXX: The whole multi_retype stuff is hack in hamlet that should be removed as
  soon as parts of an object can be retyped individually. -MN
**/

cap Dispatcher from RAM {
    /* Dispatcher */

    /**
      The Dispatcher is a special case that can be retyped several
      times to an end-point
    **/
    /** Note: This must be the first statement */
    can_retype_multiple;

    /**
      We allow the use of unknow structures. However, equality will
      be defined by address, not by structure.
    **/
    "struct dcb" dcb;       /* Pointer to kernel DCB */

    address { mem_to_phys(dcb) };
    size { objsize_dispatcher };
};

cap EndPoint from Dispatcher {
    /* IDC endpoint */

    "struct dcb" listener;  /* Dispatcher listening on this endpoint */
    lvaddr epoffset;        /* Offset of endpoint buffer in disp frame */
    uint32 epbuflen;        /* Length of endpoint buffer in words */

    address { mem_to_phys(listener) };

    /** XXX
       Preferable definitions for address and size would be as below. These
       should be used as soon as the whole multi retype hack stuff is fixed:

       address { mem_to_phys(listener + epoffset) };
       size { epbuflen };

       -MN
    **/
};

/** Then, we go back to routine **/

cap Frame from RAM from_self inherit Memory;

cap Frame_Mapping from Frame inherit Mapping;

cap DevFrame from PhysAddr from_self inherit Memory;

cap DevFrame_Mapping from DevFrame inherit Mapping;

cap Kernel is_always_copy {
    /* Capability to a kernel */
};


/* x86_64-specific capabilities: */

/* PML4 */
cap VNode_x86_64_pml4 from RAM inherit VNode;

cap VNode_x86_64_pml4_Mapping from VNode_x86_64_pml4 inherit Mapping;

/* PDPT */
cap VNode_x86_64_pdpt from RAM inherit VNode;

cap VNode_x86_64_pdpt_Mapping from VNode_x86_64_pdpt inherit Mapping;

/* Page directory */
cap VNode_x86_64_pdir from RAM inherit VNode;

cap VNode_x86_64_pdir_Mapping from VNode_x86_64_pdir inherit Mapping;

/* Page table */
cap VNode_x86_64_ptable from RAM inherit VNode;

cap VNode_x86_64_ptable_Mapping from VNode_x86_64_ptable inherit Mapping;


/* x86_32-specific capabilities: */

/* PDPT */
cap VNode_x86_32_pdpt from RAM inherit VNode;

cap VNode_x86_32_pdpt_Mapping from VNode_x86_32_pdpt inherit Mapping;

/* Page directory */
cap VNode_x86_32_pdir from RAM inherit VNode;

cap VNode_x86_32_pdir_Mapping from VNode_x86_32_pdir inherit Mapping;

/* Page table */
cap VNode_x86_32_ptable from RAM inherit VNode;

cap VNode_x86_32_ptable_Mapping from VNode_x86_32_ptable inherit Mapping;

/* ARM specific capabilities: */

/* L1 Page Table */
cap VNode_ARM_l1 from RAM inherit VNode {
    size { objsize_vnode_arm_l1 };
};

cap VNode_ARM_l1_Mapping from VNode_ARM_l1 inherit Mapping;

/* L2 Page Table */
cap VNode_ARM_l2 from RAM inherit VNode {
    size { objsize_vnode_arm_l2 };
};

cap VNode_ARM_l2_Mapping from VNode_ARM_l2 inherit Mapping;

/* ARM AArch64-specific capabilities: */

/* L0 Page Table */
cap VNode_AARCH64_l0 from RAM inherit VNode;

cap VNode_AARCH64_l0_Mapping from VNode_AARCH64_l0 inherit Mapping;

/* L1 Page Table */
cap VNode_AARCH64_l1 from RAM inherit VNode;

cap VNode_AARCH64_l1_Mapping from VNode_AARCH64_l1 inherit Mapping;

/* L2 Page Table */
cap VNode_AARCH64_l2 from RAM inherit VNode;

cap VNode_AARCH64_l2_Mapping from VNode_AARCH64_l2 inherit Mapping;

/* L3 Page Table */
cap VNode_AARCH64_l3 from RAM inherit VNode;

cap VNode_AARCH64_l3_Mapping from VNode_AARCH64_l3 inherit Mapping;

/** IRQTable and IO are slightly different **/

cap IRQTable is_always_copy {
    /* IRQ Routing table */
    /**
       When testing two IRQTable caps for is_copy, we always return True: all
       IRQ entries originate from a single, primitive Cap. Grand'pa Cap, sort
       of.
    **/
};

cap IRQDest {
	/* IRQ Destination capability.
       Represents a slot in a CPUs int vector table.
       Can be connected to a LMP endpoint to recv this interrupt. */
    eq uint64 cpu;
    eq uint64 vector;
};

cap IRQSrc from_self {
	/* IRQ Source capability.
       Represents an interrupt source. It contains a range of interrupt
       source numbers. */ 
	eq uint64 vec_start;
	eq uint64 vec_end;
};

cap IO {
    /* Legacy IO capability */
    eq uint16 start;
    eq uint16 end;          /* Granted IO range */
};

/* IPI notify caps */
cap Notify_IPI {
    eq coreid coreid;
    eq uint16 chanid;
};

/* ID capability, system-wide unique */
cap ID {
    eq coreid coreid; /* core cap was created */
    eq uint32 core_local_id; /* per core unique id */
};

cap PerfMon is_always_copy {
};

/** KernelControlBlock represents a struct kcb which contains all the pointers
 *  to core-local global state of the kernel.
 **/
cap KernelControlBlock from RAM {
    "struct kcb" kcb;

    address { mem_to_phys(kcb) };
    /* base page size for now so we can map the kcb in boot driver */
    size { objsize_kcb };
};

cap IPI is_always_copy {};
