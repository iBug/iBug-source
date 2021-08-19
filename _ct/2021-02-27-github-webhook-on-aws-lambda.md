---
title: "在 AWS Lambda 上部署一个 GitHub webhook"
tags: github aws
redirect_from: /p/41-cn
header:
  overlay_image: /image/header/mountain-5.jpg
---

前段时间我写了一个 Telegram bot 来接受 GitHub 上的仓库动态，比如有人 push 了，或者 CI 跑完了/跑挂了等。为了接受 GitHub 的“推送通知”，我需要一个 webhook 的接收器。实话讲，用 [Flask][flask] 或者 [Sinatra][sinatra] 写一个然后扔 VPS 上挂着并不困难，但是考虑到维护 VPS 和部署等需要的精力，我决定借这个机会尝试一下无服务器（serverless）的方案，也就是 AWS Lambda 云函数。

<small>[There's an English version of this article!](/p/41)</small>

  [flask]: https://palletsprojects.com/p/flask/
  [sinatra]: http://sinatrarb.com/

## 创建 AWS Lambda 函数 {#aws-lambda}

之前在 AWS Educate 那里白嫖过代金券，所以本文就跳过了注册 AWS 账号的部分了。直接登录 [AWS 管理控制台][aws-console]准备开始工作。

  [aws-console]: https://console.aws.amazon.com/

在一大堆让人眼花缭乱的服务中找到 [**Lambda**][lambda-home] 的入口。

  [lambda-home]: https://console.aws.amazon.com/lambda/home

![AWS Management Console Home](/image/aws/console-home-1.png)

创建一个新的 Lambda 函数，选择 Python 3.8 为运行环境。

![Create new Lambda function](/image/aws/lambda-create-function-1.png){: .border }

点击 Create 后函数就创建好了，进入函数的编辑页面，可以看到有一些“初始代码”已经填好了。

```python
import json

def lambda_handler(event, context):
    # TODO implement
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }
```

现在我们还不知道这个代码能赶啥或者怎么改，所以先去看 API Gateway，毕竟那个才是 webhook 的接收端入口。

## Setting up AWS API Gateway {#api-gateway}

打开 [AWS API Gateway 控制台][apigw-home]，点击右上角的 **Create API**。

  [apigw-home]: https://console.aws.amazon.com/apigateway/main

![Create API](/image/aws/api-gateway-new-1.png){: .border }

在下一个界面中选中刚才创建的 Lambda 函数作为一个 integration。

![Configure integrations](/image/aws/api-gateway-new-2.png){: .border }

接下来是 Routes（路由）。路由决定了 HTTP 的路径应该怎么分配（调度）到不同的 integrations 上。一个默认的路由已经预先填好了。

![Configure routes (1)](/image/aws/api-gateway-routes-1.png){: .border }

不过这里我们刚才创建的 Lambda 函数是唯一的 integration，我们希望在 Lambda 里自己处理路由（就像 Flask 的 `@app.route` 一样），所以先把默认填上的那个路由删掉，重新填入 `$default`。这里 `$default` 是一个特殊值，可以看到 Method 那里会变灰。

![Configure routes (2)](/image/aws/api-gateway-routes-2.png){: .border }

创建完成后就可以试一下这个 API Gateway 能不能用了。

```console
ubuntu@iBug-Server:~ $ curl https://nad73szpz7.execute-api.us-east-1.amazonaws.com/
"Hello from Lambda!"
ubuntu@iBug-Server:~ $
```

## 编写 Lambda 函数 {#lambda-code}

现在基建搭好了，可以开始写接收 webhook 代码了。不过首先我们得知道传进来的那两个 `event` 和 `context` 长啥样，以及客户端发来的 HTTP 请求是怎么进我们的 Lambda 函数的。一个很简单的办法就是临时改一下代码，把收到的 `event` 和 `context` 直接返回（显示）出来。

方便起见，这里我就直接贴上一个样例吧：

<details markdown="1">
<summary markdown="1">
`event` 对象的参考内容
</summary>

```json
{
  "version": "2.0",
  "routeKey": "$default",
  "rawPath": "/api-test",
  "rawQueryString": "taoky=strong",
  "headers": {
    "accept": "*/*",
    "accept-encoding": "gzip",
    "cdn-loop": "cloudflare",
    "cf-connecting-ip": "2001:db8::1",
    "cf-ipcountry": "XX",
    "cf-pseudo-ipv4": "255.255.255.255",
    "cf-ray": "8b8cca72b23e09a5-NRT",
    "cf-request-id": "d2160d7f1100000738c5e62000000001",
    "cf-visitor": "{\"scheme\":\"https\"}",
    "content-length": "0",
    "host": "api.example.com",
    "user-agent": "curl/7.68.0",
    "x-amzn-trace-id": "Root=1-8dab11ae-d63d4eec890259ddab5a7709",
    "x-forwarded-for": "2001:db8::1, 162.158.118.243",
    "x-forwarded-port": "443",
    "x-forwarded-proto": "https",
    "x-custom-header": "hello"
  },
  "queryStringParameters": {
    "taoky": "strong"
  },
  "requestContext": {
    "accountId": "166333366666",
    "apiId": "nad73szpz7",
    "domainName": "api.example.com",
    "domainPrefix": "api",
    "http": {
      "method": "POST",
      "path": "/api-test",
      "protocol": "HTTP/1.1",
      "sourceIp": " 162.158.118.243",
      "userAgent": "curl/7.68.0"
    },
    "requestId": "ZcOQCw-WICLEQdg=",
    "routeKey": "$default",
    "stage": "$default",
    "time": "20/Jan/2021:16:40:00 +0000",
    "timeEpoch": 1611160800000
  },
  "body": "Cg==",
  "isBase64Encoded": true
}
```
</details>

几个注意事项：

- `isBase64Encoded` 指的是 `body` 有没有经过 Base64 编码。在以上样例中 POST 进来的实际数据就是一个换行符
- `body` 可能不存在，例如对于 GET 请求
- `headers` 的键（key）全部是小写的，不过我没在 AWS 的文档中找到相关说明，因此这个我不敢保证，也有可能是因为我把我的自定义域名挂在 Cloudflare 上了

现在我们有足够的信息、知道我们的 Lambda 函数该怎么写了。我们可以先稍微扩充一点点内容：

```python
def lambda_handler(event, context):
    route = event["rawPath"]
    if route == "/api-test":
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps(event),
        }
    elif route == "/github-webhook":
        # TODO Write webhook receiver code
        pass
```

实际处理 GitHub webhook 的代码写起来应该也不困难了。下面是一个简单的例子，通过签名来验证 webhook 真的是 GitHub 发来的：

```python
import base64
import hashlib
import hmac
import os
```

```python
secret = os.environ['MY_ENV_VAR']
signature = event['headers']['x-hub-signature'].split("=")[1]
body = event.get('body', "")
if event['isBase64Encoded']:
    body = base64.b64decode(body)

hashsum = hmac.new(signature, secret, hashlib.sha1).hexdigest()
if hashsum != signature:
    return {
        'statusCode': 401,
        'body': "Bad signature",
    }

# Do whatever you want

return {
  'statusCode': 200,
  'body': "OK",
}
```

### 配置环境变量 {#lambda-environment-variables}

在上面的代码中，我把 webhook 用的 secret 放在环境变量里了，所以我们需要把这个环境变量添加到 Lambda 函数中。

回到 Lambda 控制台，往下找到 Environment variables 部分，在这里就可以管理函数使用的环境变量。

![Lambda - Environment variables](/image/aws/lambda-environment-variables-1.png){: .border }

## 更多 webhook 功能 {#customization}

现在我们已经实现了一个基本的 webhook 处理函数了，可以发挥想象实现任何好玩的功能了，例如：

- 对接 Slack 为新的 git push 和 CI 运行结果推送通知
- 对接一个 Telegram bot 进行消息推送
- 运行 Netlify 或者 Vercel 的网页部署
- 在多个仓库中联动（例如启动其他仓库的 GitHub Actions）
- ……

## 杂谈 {#others}

AWS Lambda 提供了每月 40 万 GB-秒的免费 Lambda 运行时间，并且这个免费额度是永久的，但是 API Gateway 并没有永久免费的额度，价格是每 100 万个 HTTP 请求收费 1 美元（US\$ 1.00）。除非你搞了一个公开服务并且还比较热门，这部分的开销应该是不大的。

另外，AWS 的出站流量每月前 1 GB 也是免费的，在此之后每 GB 收费 9 美分（US\$ 0.09），也就是说出站流量还是需要注意一下的，比如（从 Lambda 函数）向外传输图片等资源。

以上价格均为美东一区（US East 1, N. Virginia）的参考价格，其他地区的价格各有不同（但是普遍比美国区贵），因此运行大量函数等还是需要关注一下开销的。

## 额外内容：添加自定义域名 {#custom-domain}

结束本文前我想再补充一个点：AWS API Gateway 支持自定义域名，这对于想完全掌控自己的 API 的人来说是件好事.jpg

你可能已经注意到 API Gateway 控制台左边的 Custom Domain Names 了。点进去，在左边的 Domain names 方块点 Create，输入你准备给这个 API 用的域名，例如 `api.example.com`，保存即可，其他设置项使用默认值就行。保存完成后你应该在这个界面：

![API Gateway - Custom domain](/image/aws/api-gateway-custom-domain-1.png){: .border }

现在去你的 DNS 服务商那里为刚才设置的 API 域名添加一条 CNAME 记录，指向控制台给出的这个 `execute-api` 域名。如果你的域名在 Cloudflare 上解析的话，你也可以开启 Cloudflare 的 CDN 设定（橙色云图标）来加速这个 API 域名。

接下来要为这个新域名添加 API mapping。在图中中间的位置点击 API mapping 标签，然后选择右边的 Configure API mappings。添加一个新的映射，选择刚才创建的 API 以及 `$default` state，并且给它分配一个子路径（如果你想的话），如图所示：

![API Gateway - Custom domain - API mapping](/image/aws/api-gateway-custom-domain-2.png){: .border }

<div class="notice--primary" markdown="1">
#### <i class="fas fa-fw fa-sun"></i> 不用担心路径映射问题
{: .no_toc }

API Gateway 向 Lambda 传入的 `rawPath` 参数是已经去掉刚才设置的子路径后（如果有）剩下的部分。例如，当你设置子路径为 `/hello` 的时候，若你访问 `https://api.example.com/hello/world`，那么 Lambda 函数收到的 `rawPath` 参数还是 `/world`。也就是说，你无需在 Lambda 里适配这个子路径。
</div>

现在我们的 GitHub webhook 接收器就位于 `https://api.example.com/github` 了，我们的 "API test" 地址则是 `https://api.example.com/github/api-test`。

如果你希望你的 API 能通过 HTTPS 加密连接访问的话，你需要在 AWS Certificate Manager 中申请一个 SSL 证书。如果你的域名使用 Cloudflare 解析的话，你也可以直接使用 Cloudflare 提供的 HTTPS 访问，此时你需要注意加密类型要选择 Flexible 或 Full，而不是 Full (Strict)。
