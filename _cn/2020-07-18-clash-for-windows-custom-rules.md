---
title: "Clash for Windows 自定义规则整合"
tags: clash
---

自从今年年初换了机场之后，我从 [Shadowsocks-Windows][1] 换到了 Clash for Windows。Clash 确实比纯 SS 好用多了，尤其是订阅功能，特别是订阅里还可以自带一系列分流规则。不过我用的那个订阅规则不够完善，想要自己添加一些。以前用 SS 的时候，我[自己写了 PAC 脚本][2]用于实现分流，当然可控性也更好，这次不方便用 PAC 了，就得研究研究 CFW 的功能了，好在有个 Mixin 可以用。

{% include airport.html no_en="true" %}

首先给出 [CFW 关于 Mixin 的说明文档](https://docs.cfw.lbyczf.com/contents/mixin.html)。

这里传入的 `content` 就是你的 YAML 配置文件（也可能是来自订阅的）。要访问该 YAML 中的内容，可以使用 `content.key` 或者 `content["key"]` 的方式。

例如我使用 OneDrive Business，上传下载的网址以 `sharepoint.com` 结尾，为了让 Clash 直连 ODB，使用 [JavaScript 的 `unshift()`][3] 在订阅的规则前面插入一条新规则。

```yaml
cfw-profile-mixin: |
  module.exports.parse = async function({ content, name, url }, { axios, yaml, notify }) {
    content.rules.unshift("DOMAIN-SUFFIX,sharepoint.com,DIRECT");
    return content;
  }
```

当然有了 JS 之后还可以进行更高级的操作，比如我把订阅里的香港线路都提取出来整合成了一个 Load Balance 选项。

```javascript
module.exports.parse = async function({content, name, url}, {axios, yaml, notify}) {
  content.rules.unshift("DOMAIN-SUFFIX,sharepoint.com,DIRECT");
  proxies = [];
  for (let proxy of content.proxies) {
    if (proxy.server === undefined) continue;
    if (proxy.name.indexOf('Hong Kong') !== -1) {
      proxies.push(proxy.name);
    }
  }
  if (proxies.length > 0) {
    content['proxy-groups'].push({
      'name': 'Load Balance',
      'type': 'load-balance',
      'proxies': proxies,
      'url': 'http://cp.cloudflare.com/generate_204',
      'interval': 3
    });
    content['proxy-groups'][0].proxies.unshift("Load Balance");
  }
  return content;
}
```

Clash for Windows 0.11.0 之后不再使用 `config.yaml` 里的配置，而是提供了一个 Settings 界面，可以手动输入 YAML 或者 JavaScript 作为 mixin。首先在 Mixin 那里选择模式为 JavaScript，然后在对应的 Edit 框里输入代码，保存后刷新订阅即可。

![image](/image/cfw/settings.png)

![image](/image/cfw/js-mixin.png)


  [1]: https://github.com/shadowsocks/shadowsocks-windows
  [2]: https://github.com/iBug/pac
  [3]: https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Global_Objects/Array/unshift
