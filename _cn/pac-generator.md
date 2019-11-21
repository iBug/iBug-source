---
title: "PAC 生成器"
date: 2019-11-20
tags: generators
toc: false
show_date: false
read_time: false

hidden: true
---

<div id="result" markdown="1">

```
点下面的 [生成] 按钮
```

<a id="generate" class="btn btn--success" href="#" onclick="buildPac()">生成</a>
<a id="download" class="btn btn--primary disabled" download="pac.txt" href="#">下载</a>
</div>
<style>
#result div.highlight {
  overflow-x: hidden;
  overflow-y: scroll;
  max-height: 10em;
}
</style>

<script type="text/javascript">
function toHex(number) {
  return "0x" + ("00000000" + number.toString(16).toUpperCase()).slice(-8);
}

function buildPac() {
  $("#result pre > code").text("请稍候 / Please wait...");
  $.get(
    "https://ibugone.com/get/?target=http%3A%2F%2Fwww.ipdeny.com%2Fipblocks%2Fdata%2Faggregated%2Fcn-aggregated.zone",
    function (data) {
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
    }
  );
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
