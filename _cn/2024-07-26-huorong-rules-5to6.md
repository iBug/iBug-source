---
title: "将火绒 5.0 规则转换为 6.0"
tags: []
redirect_from: /p/70
hidden: true
---

就这么一点微小的差别，真是折腾人，写点 JavaScript 来转换一下吧。

对于「自定义规则」：

- JSON 格式，最外层的 `ver` 从 `5.0` 变成了 `6.0`
- 每条规则多了 `cmdline`（完整的命令行）、`p_procname`（父进程名）、`p_cmdline`（父进程的完整命令行）三个字段
- 每条文件规则多了个 `res_cmdline`，不知道是干嘛的

对于「自动处理规则」：

- 同样的 `ver` 从 `5.0` 变成了 `6.0`
- 每条自动处理规则多了 `cmdline`（完整的命令行）、`p_procname`（父进程名）、`p_cmdline`（父进程的完整命令行）、`res_cmdline`（不知道干嘛的）四个字段

```html

<input id="fileInput" type="file" name="file" accept=".json" />
<a id="download" class="btn btn--primary">下载</a>

<div class="language-text highlighter-rouge">
  <div class="highlight">
    <pre class="highlight"><code id="fileContent">请先上传文件</code></pre>
  </div>
</div>

<script type="text/javascript">
function processHipsuser(file) {
  file.ver = "6.0";
  for (let rule of file.data) {
    rule.cmdline = "*";
    rule.p_procname = "*";
    rule.p_cmdline = "*";
    for (let policy of rule.policies) {
      policy.res_cmdline = "*";
    }
  }
  return file;
}

function processHipsuserAuto(file) {
  file.ver = "6.0";
  for (let key in file.data) {
    let rules = file.data[key];
    for (let rule of rules) {
      rule.cmdline = "*";
      rule.res_cmdline = "*";
      rule.p_procname = "*";
      rule.p_cmdline = "*";
    }
  }
  return file;
}

function handleFileSelect(event) {
  const reader = new FileReader()
  const downloadButton = document.getElementById('download');
  reader.onload = function(event) {
    var file = JSON.parse(event.target.result);
    if (file.tag === "hipsuser") {
      file = processHipsuser(file);
    } else if (file.tag === "hipsuser_auto") {
      file = processHipsuserAuto(file);
    } else {
      file = "Unknown file type";
    }
    let output = JSON.stringify(file, null, 2);
    document.getElementById('fileContent').textContent = output;

    downloadButton.href = URL.createObjectURL(new Blob([output], {type: 'application/json'}));
  };

  let file = event.target.files[0];
  reader.readAsText(file);
  let newname = file.name.replace(/\.json$/i, "-6.0.json");
  downloadButton.download = newname;
}

document.getElementById('fileInput').addEventListener('change', handleFileSelect, false);
</script>
