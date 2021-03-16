---
title: "解决 Win10 自带微软输入法卡顿"
tags: windows
---

昨天开始我用 Windows 10 自带的微软输入法开始出现了严重的卡顿，表现是时不时的按下键盘后要等一秒钟才会出现候选列表，尤其是在切换窗口的时候能卡 2-3 秒。进入 Win10 设置应用，找到微软拼音输入法，把所有设置都改了一遍，把云联想也关了，还是没啥变化。

最后在网上找了一圈，碰上[百度经验][1]有用的时候了，根据指示检查 `%AppData%\Microsoft\InputMethod\Chs` 目录，发现里面有 6.5 万多个文件和 1 个文件夹：

![image](/image/windows/microsoft-ime-chs-files.png)

删掉这个目录之后问题立刻就消失了（不过光删它也删了一段时间）。删除后这个文件夹会很快重新冒出来，但是只要它里面没有太多文件，就没问题。

为了再次确认这个问题的产生原因，我又把那一堆文件全部重新“制造”出来：

```python
import os
from pathlib import Path

os.chdir("C:\\Users\\iBug\\AppData\\Roaming\\Microsoft\\InputMethod\\Chs")

for i in range(2**16):
    Path(f"UDP{i:X}.tmp").touch()
```

果然，Python 一运行完，输入法就开始卡了，所以接下来又把这一堆东西再删掉一遍，问题解决。

  [1]: https://jingyan.baidu.com/article/6f2f55a11f1117b5b83e6c63.html
  [2]: /image/windows/microsoft-ime-chs-files.png
