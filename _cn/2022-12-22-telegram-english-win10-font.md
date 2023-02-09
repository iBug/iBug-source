---
title: "修复 Telegram Desktop 在英文版 Windows 10 中字体显示不正常的问题"
tags: windows
redirect_from: /p/55
toc: false
---

Telegram Desktop 在英文版 Windows 10 中字体显示可以说是十分糟糕的了。例如，由成功人士 K 教授发的这样一段话：

> 门上插刀 直字拐弯 天顶加盖 船顶漏雨

在 TG Desktop 中默认的显示效果如下：

![Telegram Desktop Chinese rendering](/image/windows/telegram-desktop-font-rendering.png)

在 Google 中不难查到，这是由于英文版系统中日语字体的优先级高于中文字体，导致为每个字选择字体时的差异。网上的方法基本上就是修改这一处注册表，手工把中文字体优先级调高。以[这个知乎回答](https://www.zhihu.com/question/35739625)为例：

> 打开 Regedit，进入 `HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Fontlink\SystemLink`，点开 Segoe UI（原文说的是 Microsoft Sans Serif，但其实只有改了 Segoe UI 才有效），把下面这两行挪到最上面来：
>
> ```text
> MSYH.TTC,Microsoft YaHei UI,128,96
> MSYH.TTC,Microsoft YaHei UI
> ```

很遗憾这个方法在我这里试了无效，最后辗转找到了 [Font problem with the display of Chinese content in the Telegram Windows client \| QuantumAlgorithm's Portal](https://qamoe.cyou/2021/11/10/17/30) 这篇文章，把 Regional format 改成了 Chinese (Simplified, China)，重启 TG Desktop，成功了。

但是这带来了另一个问题：系统中的各种时间货币显示方式（即地区相关的内容）都变成了中文，这我也不喜欢；但是只要把 Regional format 改回 English (United States)，那么问题又回来了。

正好我手边有一台旧电脑，它没有这个字体问题，并且它的 Regional format 还是 English，我就翻了一下注册表对比各种设置，最后灵机一动发现了区别。

## 解决方法

进入 `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes`，把 `MS Shell Dlg` 和 `MS Shell Dlg 2` 的值都改成 `Microsoft YaHei`，然后重启 TG Desktop，问题解决。

对于 Telegram Desktop v4.6.0 和 v4.6.1，此方法会失效，**只需要更新到 v4.6.2 以上即可**。详情见 [<i class="fab fa-github"></i> TDesktop#25825](https://github.com/telegramdesktop/tdesktop/issues/25825) 的讨论。
{: .notice }

这个方法应该是我之前尝试解决 Windows 资源管理器显示中文字体异常时找到的，没想到它居然是解决 TG Desktop 字体问题的关键。

P.S. 截至本文发稿时，这个方法应该是全网首发。

<div class="notice--primary" markdown="1">
This blog article is licensed under the [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) license.

Part of this article is adapted from <https://qamoe.cyou/2021/11/10/17/30>.
</div>
