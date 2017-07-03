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
<!--more-->
# 方法比较
为了编译Barrelfish平台上的应用，有两种方法。

## 使用Hakefile
模仿Barrelfish的其他系统组件，把应用的所有源文件和库依赖都写在Hakefile中，利用Barrelfish的构建系统Hake来生成编译命令。
- 优点
Hake会自动添加必要的编译选项，如果每个C文件都可以编译通过，只要Hakefile中的库依赖填写正确，那么链接过程基本不会出错。
另外，当库的源代码发生变化后，执行make命令就可以自动重新构建应用。
- 缺点
一些较大的工具源码文件比较多，依赖关系错综复杂，有的还需要通过宏定义来对功能进行定制。只有搞清楚所有依赖和需要的宏定义才可以写出正确的Hakefile。

## 在configure过程中提供所有的编译选项
autoconf是linux下应用的常用构建方式，这类应用编译时分为configure和make两个步骤。在configure步骤时，在CFLAGS环境变量中加入-nostdlib和-nostdinc等参数来定义头文件和库文件的搜索位置，从而实现在make时只使用Barrelfish的头文件和库。
- 优点
不用分析源码间的依赖关系，使用configure可以自动分析系统内可用的库函数和头文件，并生成正确的config.h。一般来说configure步骤通过之后，make步骤是很容易通过的。如果缺少必要的库函数或者头文件，那么configure步骤就会失败并有提示。
- 缺点
与宿主系统的环境混合在一起，
若应用中掺杂了一些自定义的编译步骤，不仅configure步骤有可能无法正确识别环境，生成错误的config.h，也有可能会导致目标文件中链接到宿主系统的代码，使得程序无法再Barrelfish中正确运行。

## 使用chroot构建编译环境
使用chroot可以切换到一个空的根目录，根目录中的所有文件都是可控的，因此，编译时一定不会被宿主系统污染，也可以通过设置环境变量使得gcc在编译所有程序时，都使用Barrelfish的库和头文件。消除了第二种方法的缺点。

# 步骤
假设新的根目录位于/my/root目录中。为了方便说明，把该目录导出到环境变量中。
```bash
export root=/my/root
```
1. 挂载必要的文件系统
命令如下
```bash
mkdir -p $root/sys $root/proc $root/dev
sudo mount --bind /sys $root/sys
sudo mount --bind /sys $root/proc
sudo mount --bind /sys $root/dev
```

2. 复制必要的程序
此时该根目录中没有任何可用的程序，如果直接使用chroot命令进入目录会有如下错误。
```bash
> sudo chroot /my/root /bin/bash
chroot: failed to run command ‘/bin/bash’: No such file or directory
```
即使把/bin/bash复制到``/my/myroot/bin``中，依然会有该提示。不过注意，虽然提示相同，但是产生的原因却不同，前者是/bin/bash文件不存在，后者是bash运行所需要的动态链接库文件不存在。因此还需要复制运行时需要的动态链接库。
```bash
> cp /bin/bash /my/root/bash
> ldd /bin/bash
	linux-vdso.so.1 (0x00007ffd4d7cd000)   #对该项的说明见https://en.wikipedia.org/wiki/VDSO
	libreadline.so.7 => /usr/lib/libreadline.so.7 (0x00007f8d2bbe9000)
	libdl.so.2 => /usr/lib/libdl.so.2 (0x00007f8d2b9e5000)
	libc.so.6 => /usr/lib/libc.so.6 (0x00007f8d2b640000)
	libncursesw.so.6 => /usr/lib/libncursesw.so.6 (0x00007f8d2b3d3000)
	/lib64/ld-linux-x86-64.so.2 (0x00007f8d2be37000)
> cp /usr/lib/libreadline.so.7 $root/usr/lib/libreadline.so.7
> cp /usr/lib/libdl.so.2 $root/usr/lib/libdl.so.2
> cp ... $root/...
```
依赖复制完后，再次使用chroot命令，就可以成功进入了。但是此时并有任何其他的工具，诸如make，ls，gcc等命令都无法使用，还需使用上面的方法把这些命令复制到``$root``中才可以。
此外，注意复制正确的gcc平台版本，arm，x86等平台是有不同的gcc相对应。如arm版gcc一般名为arm-linux-eabi-gcc。
** 需要注意的是，gcc在运行时还会依赖/usr/lib/gcc/[x86_64, x86, arm]-linux-gnu/目录下的文件，否则在编译c文件时，会提示cc1命令未找到。**

3. 复制Barrelfish的头文件和库
假设宿主机上Barrelfish位于``$barrelfish``中，chroot后位于``/bar(宿主机的$root/bar)``中，那么可以使用如下的命令进行复制。
** 假设编译的是x86_64版本，编译的目录位于``$barrelfish/buildx86_64``中 **
以下目录需要被复制
```bash
# 头文件
cp   $barrelfish/include                                   $root/bar/.                                -ruL
cp   $barrelfish/lib/newlib/newlib/libc/include            $root/bar/lib/newlib/newlib/libc           -ruL
cp   $barrelfish/lib/lwip/src/include/ipv4                 $root/bar/lib/lwip/src/include             -ruL
cp   $barrelfish/lib/lwip/src/include                      $root/bar/lib/lwip/src                     -ruL
# 库文件
cp   $barrelfish/buildx86_64/x86_64/include                $root/bar/buildx86_64/x86_64               -ruL
cp   $barrelfish/buildx86_64/x86_64/lib                    $root/bar/buildx86_64/x86_64               -ruL
cp   $barrelfish/buildx86_64/x86_64/errors                 $root/bar/buildx86_64/x86_64               -ruL
cp   $barrelfish/buildx86_64/x86_64/usr/drivers/megaraid   $root/bar/buildx86_64/x86_64/usr/drivers   -ruL
```

4. 配置chroot后的环境变量
为了让新环境的gcc能找到正确的头文件和库，如libc等，需要设置如下环境变量。
```bash
# For convenience
barroot=/bar
build=$barroot/buildx86_64
plat=x86_64
# ----------------------------------
# 
# -----影响GCC的环境变量-------------
# 影响GCC的头文件搜索路径，该环境变量定义的路径优先级 < -I定义的路径 < 默认搜索路径。好处是任何时候调用GCC都起作用，缺点是优先级太低。
export C_INCLUDE_PATH="${barroot}/include:${barroot}/include/arch/x86_64:${barroot}/lib/newlib/newlib/libc/include:${barroot}/include/c:${barroot}/include/target/x86_64:${barroot}/lib/lwip/src/include/ipv4:${barroot}/lib/lwip/src/include:${build}/${plat}/include"
# 影响库文件搜索路径
export LIBRARY_PATH="${build}/${plat}/lib ${build}/${plat}/errors"
# ----------------------------------
#
# -----影响configure的环境变量--------
export CFLAGS="-std=c99 -static -U__STRICT_ANSI__ -Wstrict-prototypes -Wold-style-definition \
	-Wmissing-prototypes -fno-omit-frame-pointer -fno-builtin -nostdinc -nostdlib -U__linux__ \
	-Ulinux -Wall -Wshadow -Wmissing-declarations -Wmissing-field-initializers -Wtype-limits \
	-Wredundant-decls -m64 -mno-red-zone -fPIE -fno-stack-protector -Wno-unused-but-set-variable \
	-Wno-packed-bitfield-compat -Wno-frame-address -D__x86__ -DBARRELFISH -DBF_BINARY_PREFIX=\"\" \
	-D_WANT_IO_C99_FORMATS -DCONFIG_LAZY_THC -DCONFIG_SVM -DUSE_KALUGA_DVM -DCONFIG_INTERCONNECT_DRIVER_LMP \
	-DCONFIG_INTERCONNECT_DRIVER_UMP -DCONFIG_INTERCONNECT_DRIVER_MULTIHOP \
	-DCONFIG_INTERCONNECT_DRIVER_LOCAL -DCONFIG_FLOUNDER_BACKEND_LMP \
	-DCONFIG_FLOUNDER_BACKEND_UMP -DCONFIG_FLOUNDER_BACKEND_MULTIHOP \
	-DCONFIG_FLOUNDER_BACKEND_LOCAL -Wpointer-arith -Wuninitialized \
	-Wsign-compare -Wformat-security -Wno-pointer-sign -Wno-unused-result \
	-fno-strict-aliasing -D_FORTIFY_SOURCE=2 \
	-I${barroot}/include -I${barroot}/include/arch/x86_64 \
	-I${barroot}/lib/newlib/newlib/libc/include -I${barroot}/include/c -I${barroot}/include/target/x86_64 \
	-I${barroot}/lib/lwip/src/include/ipv4 -I${barroot}/lib/lwip/src/include -I${build}/${plat}/include"
# 还有个环境变量名叫LDFLAGS，该变量在gcc调用命令中的展开位置位于输入文件之前，会导致undefined references错误。
export LIBS="-Wl,-z,max-page-size=0x1000 -Wl,--build-id=none ${build}/${plat}/lib/crt0.o \
	${build}/${plat}/lib/crtbegin.o ${build}/${plat}/lib/libssh.a \
	${build}/${plat}/lib/libopenbsdcompat.a \
	${build}/${plat}/lib/libzlib.a ${build}/${plat}/lib/libposixcompat.a \
	${build}/${plat}/lib/libterm_server.a ${build}/${plat}/lib/libvfs.a \
	${build}/${plat}/lib/libahci.a ${build}/${plat}/lib/libmegaraid.a \
	${build}/${plat}/lib/libnfs.a ${build}/${plat}/lib/liblwip.a \
	${build}/${plat}/lib/libnet_if_raw.a ${build}/${plat}/lib/libtimer.a \
	${build}/${plat}/lib/libhashtable.a ${build}/${plat}/lib/libbarrelfish.a \
	${build}/${plat}/lib/libterm_client.a ${build}/${plat}/lib/liboctopus_parser.a \
	${build}/${plat}/errors/errno.o ${build}/${plat}/lib/libnewlib.a  \
	${build}/${plat}/lib/libcompiler-rt.a ${build}/${plat}/lib/crtend.o \
	${build}/${plat}/lib/libcollections.a" 
# ------------------------------------
# 
# 环境变量展开位置
# gcc ${CFLAGS} ${程序定义的flags} ${LDFLAGS, 一系列-l命令} ${程序指定的库} -o <output> <inputs...> ${LIBS}
 ```
把以上脚本放置在``$root/env.sh``中，每次chroot后，都使用``source /env.sh``命令引入。也可在.bashrc文件中加入source命令，启动时自动引入环境变量。

# 编译程序
本章以编译grep命令为例。
复制文件所用的自动化脚本来自[BarrelfishTools仓库](https://github.com/KKRainbow/BarrelfishTools)的[cpbin.sh文件](https://github.com/KKRainbow/BarrelfishTools/blob/master/cpbin.sh)。
```bash
➜  barrelfish git:(master) ✗ ls
usr lib hake ....
➜  barrelfish git:(master) ✗ pwd
/home/sunsijie/image/barrelfish
➜  barrelfish git:(master) ✗ ls myroot
bar  bin  dev  sys ....
➜  barrelfish git:(master) ✗ cd myroot
➜  myroot git:(master) ✗ wget http://ftp.gnu.org/gnu/grep/grep-2.5.4.tar.bz2
➜  myroot git:(master) ✗ tar xf grep-2.5.4.tar.bz2
➜  myroot git:(master) ✗ mv grep-2.5.4 grep
➜  myroot git:(master) ✗ cd ..
➜  barrelfish git:(master) ✗ ./cpbin.sh
........many outputs
arch-sunsijie cd grep
arch-sunsijie mkdir build
arch-sunsijie cd build
arch-sunsijie ../configure --host=x86_64 --disable-nls --disable-perl-regexp
........many outputs
```
此时configure步骤应该是成功的，但是编译时还是会有些问题，这是因为由于newlib实现不同于glibc，导致configure时未能正确配置一些宏定义。
- 第一个错误如下。
	```bash
	../../lib/strtoumax.c:55:1: error: redefinition of 'strtoumax'
	 strtoumax (char const *ptr, char **endptr, int base)
	 ^~~~~~~~~
	In file included from ../../lib/strtoumax.c:25:0:
	/bar/lib/newlib/newlib/libc/include/inttypes.h:322:25: note: previous definition of 'strtoumax' was here
	 static inline uintmax_t strtoumax(const char *s, char **endp, int base)
	```
	解决方法，把``$root/grep/lib/strtoumax.c``文件中引用的头文件inttypes.h删除。

- 第二个错误如下。
	```
	bar/buildx86_64/x86_64/lib/libcollections.a
		../lib/libgreputils.a(regex.o): In function `regerror':
		regex.c:(.text+0xa2e4): undefined reference to `__mempcpy'
	```
	解决方法，在lib/getopt.c和lib/regex.c文件中的合适位置添加``__mempcpy``的实现。代码如下。
	```
	static void* __mempcpy(void* dst, void* src, size_t n)
	{
		return (void*)((char*)memcpy(dst, src, n) + n);
	}
	```
- 第三个错误
	第三个错误在于没有初始化vfs，不会导致编译错误，但是会导致运行时错误。需要在``$root/grep/src/grep.c:1827行``插入代码``vfs_init();``
	之后，make通过。

使用命令
```
➜  barrelfish git:(master) ✗ cp myroot/grep/build/src/grep buildx86_64/x86_64/sbin/
➜  barrelfish git:(master) ✗ echo "module /x86_64/sbin/grep" >> buildx86_64/platforms/x86/menu.lst.x86_64
```
即可在Barrelfish启动时把grep加载到ramfs中。
命令运行成功的截图如下。
{% asset_img succ.png "运行成功截图" %}
