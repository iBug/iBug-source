---
title: "在 VMware Workstation 中安装 Ubuntu"
description: "快速上手"
tagline: "快速上手"
tags: software linux
redirect_from: /p/15-cn

hidden: true
---

<sup>There's an [English](/p/15) version of this article!</sup>

零基础快速上手虚拟机安装 Ubuntu，特别是在《操作系统原理与设计》开课的时候 *#(滑稽)*。

![](/image/setup-vmware/vmware-splash.png)

# 0. 准备工作

由于本文教程安装的是带有桌面环境的 Linux 发行版，因此推荐为客户机（虚拟机）分配至少 2 GB 的内存，以保证流畅运行。由此，主机配置内存应有 6 GB 或更多。如果你的机器没有那么多内存，可以考虑安装 Ubuntu 服务器的虚拟机，实测这样的虚拟机可以在 512 MB 的内存下运行。

下载 VMware Workstation 的 [Windows][vmware-w] 或 [Linux][vmware-l] 版本，或者下载 VMware Fusion 的 [macOS][vmware-m] 版本。你需要一个产品密钥来激活 VMware Workstation Pro 或者 VMware Fusion （Google 一下一大把）。

从 [ubuntu.com][1] 获取最新的 Ubuntu 桌面版，或者从你喜欢的[镜像站][2]下载（例如[科大镜像站][3]）。 从镜像站下载的时候注意文件名应该是 `ubuntu-{版本}-desktop-amd64.iso`，其中 `{版本}` 是 Ubuntu 版本号，例如 `18.04`。

由于作者只有运行 Windows 的电脑，因此 macOS 下安装 VMware Fusion 及 VirtualBox 的教程委托朋友编写，你可以点击[这里](https://taoky.github.io/2019-02-23/installing-os-on-vm.html)阅读。

# 1. 在 Windows 下安装 VMware Workstation

打开下载好的 VMware Workstation 安装包（需要管理员权限）

![](/image/setup-vmware/vm-1.png)

点击 \[下一步\] 继续，选择一种安装方式。对于大部分人来说，选择**典型**就可以了。按照提示完成 VMware Workstation 的安装。安装完成后需要重启电脑，以确保所有组件都能正常工作。

重启后你应该能在桌面和开始菜单看到这样一个图标：

![](/image/setup-vmware/Win10-tile.png)

双击打开 VMware Workstation，接受用户协议 (EULA) 并按提示输入密钥。如果你看到下面的窗口，说明你已经成功安装 VMware Workstation。

![](/image/setup-vmware/home-page.png)

# 2. 安装 Ubuntu 桌面版的虚拟机

如上图所示，主页有三个大按钮。你可能已经发现了，第一个就是”创建新虚拟机“。点一下，然后就可以看到”创建新虚拟机向导“，如图：

![](/image/setup-vmware/nvmw-1.png)

同样，对于大部分人来说，**典型（推荐）**就像它写的那样——是推荐的选项。

在下一页，选择**安装光盘镜像**并选择刚刚下载的 Ubuntu 系统镜像（格式是 ISO）。VMware Workstation 应该检测到 Ubuntu 安装盘并提示你将使用“简易安装”来安装操作系统。

![](/image/setup-vmware/nvmw-2.png)

点击 \[下一步\] 之后，你可以指定虚拟机的主机名（系统内部的“本机名称”，用于网络连接等），以及用户名和密码。由于虚拟机是一个独立的环境，而且只为你所用，因此弱密码不会带来什么安全问题（例如，图中所有空填的都是 `vmware`，包括密码）。

![](/image/setup-vmware/nvmw-3.png)

在下一页中，你可以给这个虚拟机起个名字（这个名字将显示在菜单中），并指定一个存储位置。对大多数人来说，出于多种考虑，存储在 C 盘里不是一个期望的选择。在 Linux 或者 macOS 中，你可以将虚拟机放在你的 `$HOME` 中。如图所示，我给虚拟机起名就叫 **Ubuntu 18.04**，并将它放在 D 盘里。

![](/image/setup-vmware/nvmw-4.png)

接下来，为虚拟机创建一个虚拟磁盘。忽略 VMware 的建议值，16 GB 已经足够大多数初次接触 Ubuntu 的人使用了。本示例中我指定了 8 GB（这个容量对于示例来说足够了）。选择**将虚拟磁盘作为单个文件存储**以获得较高性能——相信你的磁盘应对大文件的能力。

![](/image/setup-vmware/nvmw-5.png)

好了，以上就是你需要指定的设置选项了。检查一下并确认虚拟机的硬件配置。你可以在这里自定义虚拟机的硬件配置，比如，删掉打印机和声卡，或者增加一些处理器核心和内存（如果你的主机有足够多的资源）。

![](/image/setup-vmware/nvmw-6.png)

![](/image/setup-vmware/nvmw-7.png)

关闭向导后，开启虚拟机。初次开机的界面如图：

![](/image/setup-vmware/u-1.png)

就像之前所说，虚拟机中安装 Ubuntu 的过程是由 VMware 的简易安装功能全自动完成的。你可以看到 Ubuntu 的安装界面，如下所示：

![](/image/setup-vmware/u-2.png)

取决于主机配置（尤其是硬盘速度），虚拟机将很快重启，新系统的第一次开机通常会比较慢。稍等片刻，你就能看到 Ubuntu 的登录界面。输入密码后，就可以看到 Ubuntu 的桌面。

![](/image/setup-vmware/u-3.png)

![](/image/setup-vmware/u-4.png)

进入桌面后，*Ubuntu 的新特性*会弹出来。你可以简单看一下，这里没有特别重要的信息。

![](/image/setup-vmware/u-5.png)

按 `Ctrl` + `Alt` + `T` 可以打开 Ubuntu 自带的终端模拟器。

![](/image/setup-vmware/u-6.png)

最后，为了快速配置 Ubuntu 的生产力，我写了一个[快速配置脚本][script]，你可以用以下命令使用它：

```shell
wget -qO setup.sh https://raw.githubusercontent.com/iBug/shGadgets/master/quick-setup.sh && bash setup.sh
```

由于该脚本使用了 `sudo`，因此过程中会提示你输入密码。另外，如果你有 GitHub 用户名，脚本也会询问，并为你配置好 Git 的设置。

  [1]: https://www.ubuntu.com/download/desktop
  [2]: https://launchpad.net/ubuntu/+cdmirrors
  [3]: https://mirrors.ustc.edu.cn/ubuntu-releases/bionic/
  [vmware-w]: https://www.vmware.com/go/getworkstation-win
  [vmware-m]: https://www.vmware.com/go/getfusion
  [vmware-l]: https://www.vmware.com/go/getworkstation-linux
  [kb]: https://kb.vmware.com/articleview?docid=2098121
  [script]: https://github.com/iBug/shGadgets/blob/master/quick-setup.sh
