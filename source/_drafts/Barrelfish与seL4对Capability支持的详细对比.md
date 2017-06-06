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

## 什么是Capability
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
从上节中介绍的类型中可以看出，计算机内的各种资源是有层次关系的。
内存空间是最基础的一种资源，PCB、EndPoint等，都是由内存空间转换而来的。Capability的类型转换就是为了模拟这种资源的层次关系。当用户程序取得一种Capability时（通常是表示一段内存空间的RAM Capability），可以使用系统调用将该Capability转换为其他类型，内核首先通过事先定义好的规则验证该转换是否合法，若合法，则会在内核空间为该进程创建一个目标类型的Capability，并把引用返回给用户程序。
类型的转换并不会导致一个Capability的删除，内核会维护Capability间的关系，

## Capability的原理
Capability的原理如下图所示。
内核通过赋予、删除、转换类型等操作，
Capability有不同的类型，并且

## Barrelfish中的Capability实现





## Capability类型对比

| fdsljakj| sun       | fdsal    |
| -         | -        |
| flkdsjal  | fdlksajf |
| flkdsajfl | fjkldsja |
