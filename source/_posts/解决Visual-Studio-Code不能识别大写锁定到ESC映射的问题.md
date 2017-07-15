---
title: 解决Visual Studio Code不能识别大写锁定到ESC映射的问题
date: 2017-07-15 15:09:27
tags:
	- vscode
categories:
	- 杂记
---

## 起因
由于我习惯于使用vim，因此无论在win下还是linux下我都把ESC和CapsLock做了交换。在使用Vscode时，我也安装了vim插件，但是在插入模式中无法使用交换后的Capslock键退出插入模式。
## 解决方法
在设置文件中修改如下选项
```
"keyboard.dispatch": "keyCode"
```
然后重启Vscode。

具体原因见该[Vscode-vim Issue](https://github.com/VSCodeVim/Vim/issues/854)以及[Vscode Issue](https://github.com/Microsoft/vscode/issues/23991)

