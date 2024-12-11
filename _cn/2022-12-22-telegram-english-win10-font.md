---
title: "修复 Telegram Desktop 在英文版 Windows 10 中字体显示不正常的问题"
tags: windows
redirect_from: /p/55
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

很遗憾这个方法在我这里试了无效，最后辗转找到了 [Font problem with the display of Chinese content in the Telegram Windows client \| QuantumAlgorithm's Portal](https://qamoe.cyou/blog/2021/11/10/17/30) 这篇文章，把 Regional format 改成了 Chinese (Simplified, China)，重启 TG Desktop，成功了。

但是这带来了另一个问题：系统中的各种时间货币显示方式（即地区相关的内容）都变成了中文，这我也不喜欢；但是只要把 Regional format 改回 English (United States)，那么问题又回来了。

正好我手边有一台旧电脑，它没有这个字体问题，并且它的 Regional format 还是 English，我就翻了一下注册表对比各种设置，最后灵机一动发现了区别。

## 解决方法（旧） {#solution-v1}

本段适用于 Telegram Desktop v4.x，而 TDesktop 在 2024 年 5 月 2 日更新了 v5.0，请见下一个章节。
{: .notice--danger }

进入 `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes`，把 `MS Shell Dlg` 和 `MS Shell Dlg 2` 的值都改成 `Microsoft YaHei`，然后重启 TG Desktop，问题解决。

对于 Telegram Desktop v4.6.0 和 v4.6.1，此方法会失效，**只需要更新到 v4.6.2 以上即可**。详情见 [<i class="fab fa-github"></i> TDesktop#25825](https://github.com/telegramdesktop/tdesktop/issues/25825) 的讨论。
{: .notice }

这个方法应该是我之前尝试解决 Windows 资源管理器显示中文字体异常时找到的，没想到它居然是解决 TG Desktop 字体问题的关键。

P.S. 截至本文发稿时，这个方法应该是全网首发。

---

Telegram Desktop v5.0 更新后加入了自选字体的功能，可以在设置中选择字体。对于一些人来说这个功能足够了，但是像我这种喜欢 v4.x 的配置（西文字体用 Open Sans，中文字体用 Microsoft YaHei）的人来说，只能设置一个 font family 显然是不够的，并且在注册表里怎么鼓捣 `FontLink` 也没用，而直接用 `FontSubstitutes` 换掉 Open Sans 会导致西文字体也变成 Microsoft YaHei，这下又不行了。

## Telegram Desktop v5.0 的解决方法 {#solution-v2}

2024 年 12 月更新，由网友 Chris 在评论区分享（iBug 测试有效）：

**用 `FontSubstitutes` 把 `Tahoma` 换成 `Microsoft YaHei UI`** 即可把 TDesktop 的中文字体变成微软雅黑，而不会影响西文字体。TDesktop 设置里的字体设置保持默认（选择 Default）即可。

具体做法是进入 `FontSubstitutes` 注册表项，在右边新建一个字符串值，名称为 `Tahoma`，值为 `Microsoft YaHei UI`，然后关闭并重启 TDesktop 即可。

原因是 TDesktop 引用的 Qt 库把默认的 fallback 字体[设成了 Tahoma](https://github.com/desktop-app/patches/commit/5d64e21844e4bc6e8aa014b14e40e10787f81677)，且实际上是在 v4.6.10 中做出的改动，所以 v4.6.10 以上的版本都应该用这个方法。

<div class="notice--primary" markdown="1">
This blog article is licensed under the [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) license.

Part of this article is adapted from <https://qamoe.cyou/blog/2021/11/10/17/30>.
</div>
