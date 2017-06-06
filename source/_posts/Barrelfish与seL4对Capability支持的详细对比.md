---
title: Barrelfish与seL4对Capability支持的详细对比
tags:
  - Barrelfish
  - seL4
  - 操作系统
  - Capability
categories:
  - Barrelfish
date: 2017-06-06 16:40:23
---

# 概述

Barrelfish采用Capability机制对系统资源进行管理，该机制源自seL4。

Capability可以看做是访问系统中各种资源的令牌。内存空间、IO端口、进程控制块（PCB），中断号，进程通信的信道等，都可以通过Capability来管理。

内核通常会在内核空间维护每个进程所持有的Capability的详细数据，而用户进程持有Capability的引用。当用户程序访问系统资源时，需要使用该资源对应的Capability的引用调用系统调用，内核检查该引用的合法性后，才会允许用户对该资源进行操作。

<!-- more -->

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
类型的转换并不会导致一个Capability的删除，内核会维护新产生的Capability与源Capability间继承的关系(Capability Derivation Tree)，若用户空间重复对一个的Capability进行类型转换操作，那么内核会拒绝该操作；若进程请求删除的一个Capability有子节点，那么内核也会同时删除子节点。
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
- [Barrelfish Capability定义文件][caps.hl]
- [seL4 Capability定义文件][structs.bf]


| 分类           | Barrelfish                  | seL4                      |
| -              | -                           | -                         |
|                | Null                        | null_cap                  |
|                |                             |                           |
| 内存空间相关   | Memory                      | untyped_cap               |
|                | PhysAddr                    |                           |
|                | Mapping                     |                           |
|                | VNode                       |                           |
|                | RAM                         |                           |
|                |                             |                           |
| Capability权限 | Kernel                      |                           |
|                |                             |                           |
| Capability管理 | CNode                       | cnode_cap                 |
|                | L1CNode                     | zombie_cap                |
|                | L2CNode                     |                           |
|                | FCNode                      |                           |
|                |                             |                           |
| 进程管理与IPC  | Dispatcher                  | domain_cap                |
|                | EndPoint                    | endpoint_cap              |
|                |                             | thread_cap                |
|                |                             | notification_cap          |
|                |                             | reply_cap                 |
|                |                             |                           |
| 页表管理       | Frame                       | frame_cap                 |
|                | Frame_Mapping               |                           |
|                | DevFrame                    |                           |
|                | DevFrame_Mapping            |                           |
|                | VNode_x86_64_pml4           | asid_control_cap          |
|                | VNode_x86_64_pml4_Mapping   | asid_pool_cap             |
|                | VNode_x86_64_pdpt           | pdpt_cap                  |
|                | VNode_x86_64_pdpt_Mapping   | pml4_cap                  |
|                | VNode_x86_64_pdir           | page_directory_cap        |
|                | VNode_x86_64_pdir_Mapping   | page_global_directory_cap |
|                | VNode_x86_64_ptable         | page_table_cap            |
|                | VNode_x86_64_ptable_Mapping | page_upper_directory_cap  |
|                | VNode_x86_32_pdpt           | small_frame_cap           |
|                | VNode_x86_32_pdpt_Mapping   |                           |
|                | VNode_x86_32_pdir           |                           |
|                | VNode_x86_32_pdir_Mapping   |                           |
|                | VNode_x86_32_ptable         |                           |
|                | VNode_x86_32_ptable_Mapping |                           |
|                | VNode_ARM_l1                |                           |
|                | VNode_ARM_l1_Mapping        |                           |
|                | VNode_ARM_l2                |                           |
|                | VNode_ARM_l2_Mapping        |                           |
|                | VNode_AARCH64_l0            |                           |
|                | VNode_AARCH64_l0_Mapping    |                           |
|                | VNode_AARCH64_l1            |                           |
|                | VNode_AARCH64_l1_Mapping    |                           |
|                | VNode_AARCH64_l2            |                           |
|                | VNode_AARCH64_l2_Mapping    |                           |
|                | VNode_AARCH64_l3            |                           |
|                | VNode_AARCH64_l3_Mapping    |                           |
|                |                             |                           |
| IO及IRQ        | IRQTable                    | io_page_table_cap         |
|                | IRQDest                     | io_port_cap               |
|                | IRQSrc                      | io_space_cap              |
|                | IO                          | irq_control_cap           |
|                |                             | irq_handler_cap           |
|                |                             |                           |
| 多核管理       | Notify_IPI                  |                           |
|                | ID                          |                           |
|                | PerfMon                     |                           |
|                | KernelControlBlock          |						   |
|                | IPI                         |                           |
|                |                             |                           |
| 虚拟化         |                             | vcpu_cap                  |
|                |                             | ept_pd_cap                |
|                |                             | ept_pdpt_cap              |
|                |                             | ept_pml4_cap              |
|                |                             | ept_pt_cap                |

- 以上为所有架构的Capability汇总。
- seL4中Capability类型由如下命令获得。
	``grep -r "tag[[:blank:]]\+\w\+_cap[[:blank:]]\+\w\+" -h --include="*.bf" | sed -e 's/tag//' -e 's/^\ \+//' -e 's/\w\+$//' | tr -d ' ' | sort | uniq``
- [EPT(Extended Page Table)](https://en.wikipedia.org/wiki/Second_Level_Address_Translation#EPT)

[caps.hl]: http://git.barrelfish.org/?p=barrelfish;a=blob;f=capabilities/caps.hl;h=5fd75c1d4e499de07a2b36fa4ccb9b05a08c6ae8;hb=ac6fbb2ea0c4b2f9a49b520feb714cf05355721a
[structs.bf]: https://github.com/seL4/seL4/blob/master/include/object/structures_32.bf

## Capability操作对比

| Barrelfish            | seL4          | 操作描述 |
| -                     | -             | -        |
| sys_create/sys_retype | UntypedRetype |          |
| caps_revoke           | CNodeRevoke   |          |
| caps_delete           | CNodeDelete   |          |
|                       |               |          |
| sys_copy_or_mint      | CNodeCopy     |          |
|                       | CNodeMint     |          |
|                       |               |          |
|                       | CNodeMove     |          |
|                       | CNodeMutate   |          |
|                       | CNodeRotate   |          |

- Barrelfish的Capability支持跨核的Delete
- Barrelfish的Retype操作具有更丰富的语义，比如可以从 *Dspather Capability* retype 为 *Endpoint Capability*。
