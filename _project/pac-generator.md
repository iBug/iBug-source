---
title: "PAC 生成器"
toc: false
comments: true
redirect_from:
  - /cn/pac-generator/
redirect_to: https://github.com/iBug/pac/releases/latest

hidden: true
---

<div class="notice--danger" markdown="1">
### <i class="fas fa-exclamation-triangle"></i> 注意
{: .no_toc }

本页面即将弃用，不再维护，请移步至[源仓库的 Releases 页面][releases]下载最新的 PAC 脚本。参见[这条留言][1]。

别忘了点 &#x2605; 哦 😊
</div>

  [releases]: https://github.com/iBug/pac/releases/latest
  [1]: https://github.com/iBug/pac/issues/2#issuecomment-462220411

本 PAC 生成器从 <http://www.ipdeny.com/ipblocks/data/aggregated/cn-aggregated.zone> 获取最新 IP 地址列表，并将其转换成适用于代理的 PAC 代码。详情请见[这个 Issue](https://github.com/shadowsocks/shadowsocks-windows/issues/1873)。

This PAC generator fetches latest IP address table from <http://www.ipdeny.com/ipblocks/data/aggregated/cn-aggregated.zone> and converts it into a PAC code suitable for proxies. For background, head over to [this issue](https://github.com/shadowsocks/shadowsocks-windows/issues/1873).

如果你有任何问题，欢迎在[项目主仓库的 Issue 列表](https://github.com/iBug/pac/issues)提出。

Any issue is welcome at the [issue board of the master repository](https://github.com/iBug/pac/issues).

### Update 1

Added support for an alternative source: <https://github.com/17mon/china_ip_list>. See [Issue #6](https://github.com/iBug/pac/issues/6) for details.

### Update 2

Added compatibility support for Shadowsocks Windows 4.1.9. See [Issue #7](https://github.com/iBug/pac/issues/7) for details.

<div id="result" markdown="1">

```
点下面的 [生成] 按钮 / Press [Generate]
```

<a id="generate" class="btn btn--success" href="#" onclick="buildPac()">生成 / Generate</a>
<a id="download" class="btn btn--primary disabled" download="pac.txt" href="#">下载 / Download</a>

<iframe src="https://ghbtns.com/github-btn.html?user=iBug&repo=pac&type=star&count=true&size=large" frameborder="0" scrolling="0" width="160px" height="30px"></iframe>

### 选项 / Settings

数据源 / Data source

<input type="radio" name="data-source" checked
  value="http://www.ipdeny.com/ipblocks/data/aggregated/cn-aggregated.zone" />
  <http://www.ipdeny.com/ipblocks/data/aggregated/cn-aggregated.zone> <br>
<input type="radio" name="data-source"
  value="https://github.com/17mon/china_ip_list/raw/master/china_ip_list.txt" />
  <https://github.com/17mon/china_ip_list>

<input type="checkbox" id="compat-419" checked /> Shadowsocks Windows 4.1.9 兼容模式 / compatibility mode

</div>

<style>
#result div.highlight {
  overflow-x: hidden;
  overflow-y: auto;
  max-height: 10em;
}
</style>

<script type="text/javascript">
function toHex(number) {
  return "0x" + ("00000000" + number.toString(16).toUpperCase()).slice(-8);
}

function buildPac() {
  $("#result pre > code").text("请稍候 / Hang on...");
  // Identify data source
  const dataSource = $("input[name='data-source']:checked").val();
  // Code source: https://github.com/iBug/pac/blob/master/code.js
  //const codeSource = "https://cdn.jsdelivr.net/gh/iBug/pac/code.js";
  const codeSource = "https://raw.githubusercontent.com/iBug/pac/master/code.js";
  const compatMode = $("#compat-419")[0].checked;
  var dataReq = $.get("https://ibugone.com/get/", {"target": dataSource});
  var codeReq = $.get(codeSource);
  $.when(dataReq, codeReq).then(function (dataObj, codeObj) {
    const timeString = new Date().toLocaleString("sv", {timeZoneName: "short"});
    let data = dataObj[0], code = codeObj[0].replace("@@TIME@@", timeString), output = code;
    output += "var CHINA = [\n";
    const lines = data.trim().split("\n");
    for (let i = 0; i < lines.length; i++) {
      let content = lines[i].split("/");
      if (content.length !== 2)
        continue;
        let addr = content[0].split(".").map(x => parseInt(x));
      let addrNum = 0;
      for (let j = 0; j < 4; j++) {
        addrNum += addr[j] << (24 - 8 * j);
      }
      addrNum = addrNum >>> 0;
      let maskNum = (0xFFFFFFFF << (32 - parseInt(content[1], 10))) >>> 0;
      output += "  [" + toHex(addrNum) + ", " + toHex(maskNum) + "]";
      if (i != lines.length - 1) {
        output += ",";
      }
      output += "\n";
    }
    output += "];";
    if (compatMode) {
      output = output.replace("\"__PROXY__\"", "__PROXY__");
    }
    $("#result pre > code").text(code + "var CHINA = [\n  // Please download for full content\n];");
    $("#download").removeClass("disabled");
    $("#download").attr("href", "data:application/octet-stream;charset=utf-8;base64," + btoa(output + "\n"));
  }, function (err) {
    $("#result pre > code").text("Unexpected error, see console log for details.");
  });
}
</script>

