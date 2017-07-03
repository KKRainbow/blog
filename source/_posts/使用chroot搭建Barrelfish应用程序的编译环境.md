---
title: 使用chroot搭建Barrelfish应用程序的编译环境
date: 2017-07-02 22:28:53
tags:
	- Barrelfish chroot
categories:
	- Barrelfish
---
# 背景
[Barrelfish](http://www.barrelfish.org/)是微软开发的一个开源操作系统。为了研究该系统目前基础设施的完善程度，需要移植一些Linux下的用户空间工具。本文介绍了使用chroot来搭建cross compile环境的过程。

# 方法比较
为了编译Barrelfish平台上的应用，有两种方法。

## 使用Hakefile
模仿Barrelfish的其他系统组件，把应用的所有源文件和库依赖都写在Hakefile中，利用Barrelfish的构建系统Hake来生成编译命令。
- 优点
Hake会自动添加必要的编译选项，如果每个C文件都可以编译通过，只要Hakefile中的库依赖填写正确，那么链接过程基本不会出错。
另外，当库的源代码发生变化后，执行make命令就可以自动重新构建应用。
- 缺点
一些较大的工具源码文件比较多，依赖关系错综复杂，有的还需要通过宏定义来对功能进行定制。只有搞清楚所有依赖和需要的宏定义才可以写出正确的Hakefile。

## 使用chroot
