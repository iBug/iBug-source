---
title: "PAC 生成器"
toc: false
comments: true
redirect_from:
  - /cn/pac-generator/

hidden: true
---

本 PAC 生成器从 <http://www.ipdeny.com/ipblocks/data/aggregated/cn-aggregated.zone> 获取最新 IP 地址列表，并将其转换成适用于代理的 PAC 代码。详情请见[这个 Issue](https://github.com/shadowsocks/shadowsocks-windows/issues/1873)。

This PAC generator fetches latest IP address table from <http://www.ipdeny.com/ipblocks/data/aggregated/cn-aggregated.zone> and converts it into a PAC code suitable for proxies. For background, head over to [this issue](https://github.com/shadowsocks/shadowsocks-windows/issues/1873).

如果你有任何问题，欢迎在[项目主仓库的 Issue 列表](https://github.com/iBug/pac/issues)提出。

Any issue is welcome at the [issue board of the master repository](https://github.com/iBug/pac/issues).

### Update 1

Added support for an alternative source: <https://github.com/17mon/china_ip_list>. See [this issue](https://github.com/iBug/pac/issues/6) for details.

<div id="result" markdown="1">

```
点下面的 [生成] 按钮 / Press [Generate]
```

<a id="generate" class="btn btn--success" href="#" onclick="buildPac()">生成 / Generate</a>
<a id="download" class="btn btn--primary disabled" download="pac.txt" href="#">下载 / Download</a>

选择数据源 / Select data source

<input type="radio" name="data-source" checked
  value="http://www.ipdeny.com/ipblocks/data/aggregated/cn-aggregated.zone" />
  <http://www.ipdeny.com/ipblocks/data/aggregated/cn-aggregated.zone> <br>
<input type="radio" name="data-source"
  value="https://github.com/17mon/china_ip_list/raw/master/china_ip_list.txt" />
  <https://github.com/17mon/china_ip_list>

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
  // Identify source
  const dataSource = $("input[name='data-source']:checked").val();
  $.ajax({
    url: "https://ibugone.com/get/",
    type: "GET",
    data: {"target": dataSource},
    success: function (data) {
      let output = $("#code-template").text();
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
      $("#result pre > code").text(output);
      $("#download").removeClass("disabled");
      $("#download").attr("href", "data:application/octet-stream;charset=utf-8;base64," + btoa(output + "\n"));
    },
    error: function (err) {
      $("#result pre > code").text("Unexpected error, see console log for details.");
    }
  });
}
</script>

<pre id="code-template" style="display: none;">
// Author: iBug &lt;ibugone.com&gt;

function belongsToSubnet(host, list) {
  var ip = host.split(".");
  ip = 0x1000000 * Number(ip[0]) + 0x10000 * Number(ip[1]) +
    0x100 * Number(ip[2]) + Number(ip[3]);

  if (ip < list[0][0])
    return false;

  // Binary search
  var x = 0, y = list.length, middle;
  while (y - x > 1) {
    middle = Math.floor((x + y) / 2);
    if (list[middle][0] < ip)
      x = middle;
    else
      y = middle;
  }

  // Match
  var masked = ip & list[x][1];
  return (masked ^ list[x][0]) == 0;
}

function isChina(host) {
  return belongsToSubnet(host, CHINA);
}

function isLan(host) {
  return belongsToSubnet(host, LAN);
}

function FindProxyForURL(url, host) {
  if (!isResolvable(host)) {
      return "__PROXY__";
  }
  var remote = dnsResolve(host);
  if (isLan(remote) || isChina(remote)) {
      return "DIRECT";
  }
  return "__PROXY__";
}

var LAN = [
  [0x0A000000, 0xFF000000],
  [0x7F000000, 0xFFFFFF00],
  [0xA9FE0000, 0xFFFF0000],
  [0xAC100000, 0xFFF00000],
  [0xC0A80000, 0xFFFF0000]
];

</pre>
