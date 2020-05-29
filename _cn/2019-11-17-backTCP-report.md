---
title: "backTCP 实验报告"
excerpt: "backTCP 是中科大 2019 年秋季《计算机网络》课程的一次实验任务"
tags: null
header:
  actions:
    - label: "<i class='fab fa-github'></i> GitHub"
      url: https://github.com/iBug/backTCP
    - label: "<i class='fas fa-file-alt'></i> 实验文档"
      url: https://github.com/iBug/backTCP-python/files/3818860/V2.0.pdf
  show_overlay_excerpt: true
redirect_from: /cn/backTCP-report/
---

# 一、实验内容

backTCP 的目标是实现面向无连接的可靠传输功能，能够解决数据包在传输过程中出现的乱序以及丢包问题。由于考虑的是无连接的网络，因此该作业不需要考虑传统 TCP 中的三次握手连接建立过程。此外，假设传输中数据不会出现错误，因此只需要考虑如何解决数据包的乱序和丢包问题。

由于实验文档缺失细节，并且助教允许在非关键位置自由发挥，因此我的实现与实验文档中的内容有以下区别：

1. 由于实验文档中指出 backTCP 是面向无连接的，因此我的实现采用了 UDP 作为传输层协议
2. 出于各种考虑，我的实现采用了修改过的 backTCP 数据包头。与实验文档中指定的包头格式的唯一区别在于我的 backTCP 包头多了一个 1 字节的域 `data_len`，使得包头总长度变成了 8 字节

因为上面两处修改涉及 backTCP 的底层结构，因此测试信道不能直接使用我公开的代码模板中的版本。当然，我也给出了一个修改版的测试信道程序，其后端实现与我的 backTCP 一致（尽管它是使用 Python 语言编写的）。该修改版测试信道在我的公开仓库的 `udp-mod` 分支中：<https://github.com/iBug/backTCP-python/tree/udp-mod>

# 二、实验环境

尽管我发布了一个使用 Python 语言编写的程序框架，但是由于我自己的代码很早就开始编写了，当初为了更加契合主题，直接使用 Linux 系统调用，因此我的代码使用 C 语言在 Linux 环境下编写。我自己经测试的系统环境为 Ubuntu 19.04 "Disco Dingo"，内核版本为 5.0，但理论上在任何较新的 Linux 系统中都可以正常运行，例如 Ubuntu 16.04, Debian 8 "Jessie" 以及 CentOS 7 等。编译环境需要 C 编译器和 Make (项目提供 `Makefile`)

# 三、实现步骤

## 3.1 通用逻辑

### 3.1.1 backTCP 头

我采用的修改版 backTCP 头结构如下所示：

```c
typedef struct _BTcpHeader {
    uint8_t btcp_sport;  // source port - unused
    uint8_t btcp_dport;  // destination port - unused
    uint8_t btcp_seq;    // sequence number
    uint8_t btcp_ack;    // acknowledgement number
    uint8_t data_off;    // data offset in bytes
    uint8_t win_size;    // window size
    uint8_t flags;       // flags
    uint8_t data_len;    // data length (excl. header)
} BTcpHeader;
```

各个域的意义如下：

- `btcp_sport`, `btcp_dport` 是助教给出的文档中的内容。我实在没想到它们有什么用，因此它们在所有数据包中都被置为零，并且被忽略
- `btcp_seq` 为 backTCP 包序号，范围为 0~255，超出范围的取模处理（模 256）
- `btcp_ack` 为 backTCP 响应序号，指示下一个期望的包编号，而不是已全部收到的包中的最大编号（实际上等于该编号 +1）。这样做的一个好处是减少了多处的 +1 -1 运算，以及潜在的由它们带来的混乱
- `data_off` 表示数据段的开始位置，本实现中应该恒为 8，因为 backTCP 头中不包含传统 TCP 头的可选字段（因此理论上它也是不必要的）
- `win_size` 指示当前发送窗口中剩余的包数量，因此连续发送的一串包中该字段应该逐渐减小至零，可供接收端参考以调整接收窗口（虽然实际上好像并没有根据发送窗口来调整接收窗口的逻辑）
- `flags` 在代码中有三个位是被使用的，但是实际上只有一个位 0x01 (重传) 会影响功能。另外两个无用字段为 0x02 (指示传输结束，实际采用另一种实现) 和 0x40 (模仿传统 TCP，指示该包为一个 ACK 包，由于各种原因未采用)
- `data_len` 是我自己加的，用于从被暂存的包中确定实际数据长度，避免产生错误输出

### 3.1.2 backTCP 连接句柄

为了方便使用与维护，我将底层的 UDP 套接字包装成为 `BTcpConnection` 句柄指针。使用方式与 `FILE*` 极为相似：

- `BTOpen` 函数打开一个 backTCP 连接，初始化底层套接字与连接属性，并返回一个指向连接元信息的指针
- `BTSend`, `BTRecv` 等函数接收一个 `BTcpConnection` 指针指示要使用的 backTCP 连接
- `BTClose` 接收一个 `BTcpConnection` 指针，进行清理工作，然后销毁这个指针

该句柄指针与 C 语言标准文件句柄指针的用法比较：

```c
BTcpConnection *conn = BTOpen(...):
FILE *fp = fopen(...);
```

```c
BTSend(conn, ...);
BTRecv(conn, ...);
fprintf(fp, ...);
fscanf(fp, ....);
```

```c
BTClose(conn);
fclose(conn);
```

### 3.1.3 backTCP 连接信息

`BTcpConnection` 结构如下：

```c
typedef struct _BTcpConnection {
    int socket;
    struct sockaddr_in addr;
    BTcpState state;
    BTcpConfig config;
} BTcpConnection;
```

其中：

- `socket` 为底层套接字所使用的文件描述符
- `addr` 指示另一端的地址（仅支持 IPv4）
- `state` 存储了连接的一些状态信息，因为一个 `BTcpConnection` 可能会被多次用于调用发送或接收函数，需要存储中间状态，就像 `FILE*` 可以多次用于调用 `fread`/`fwrite` 等函数一样
- `config` 存储了连接的一些设置信息，例如最大数据段长度、接收超时时间、ACK 超时时间等。这个字段本来是准备提供通过命令行修改 backTCP 连接属性的功能的，但是由于时间匆忙未能实现。该字段在初始化连接时会被置为默认值（最大数据长度 64 字节，ACK 超时时间为 10 ms，这两个值与实验文档中的要求一致；接收窗口 10 个包，接收超时时间为 5 ms）

## 3.2 发送逻辑

对于发送部分，`btcp_sport`, `btcp_dport` 和 `btcp_ack` 三个域是没有使用的（但是接收方返回的响应包中的 `btcp_ack` 字段会被检查）。

发送函数原型为 `size_t BTSend(BTcpConnection* conn, const void* data, size_t len)`，各参数意义如下：

- `conn` 为 backTCP 连接句柄，见 3.1.2 节
- `data` 指向待发送数据，这些数据会被分割并包装成 backTCP 包然后发送
- `len` 指示 `data` 中数据的长度
- 返回值为实际成功发出的字节数

函数首先进行必要的初始化，例如分配一些缓冲区，从 `conn->state` 中恢复必要的状态信息等。

发送函数中主体循环的逻辑为：

- 检查窗口大小，从 `data` 中读取数据，拼装数据包，并将窗口中的数据包全部发出
- 等待对面发来 ACK 包，使用 poll(2) 系统调用来检测有没有收到包，或者超时
- 根据 ACK 结果作出响应
  - 超时：将窗口中所有包重新发送一遍
  - 收到 ACK 包：检查接收方发回的 ACK 值与窗口大小，调整发送窗口位置与大小，进入下一轮循环
- 发送完全部数据后，清理（释放申请的内存、将状态信息存回 `conn->state` 中）并返回

其中，主体循环第一次迭代时的发送窗口大小为 1，即仅发出一个包然后等待接收端的响应，方便根据接收端状态进行动态调整。

## 3.3 接收逻辑

对于接收部分，`btcp_sport`, `btcp_dport`, `btcp_seq`, `data_off` 和 `data_len` 五个域是没有使用的（但发送方传来的后三个字段会被检查）

接收函数原型为 `size_t BTRecv(BTcpConnection* conn, void* data, size_t len)`，各参数意义与 `BTSend` 相同，区别是 `data` 需要可写（这是显然的）

初始化工作与发送部分相似，但在进入主体循环之前会无限期等待第一个包（因为是面向无连接的），然后根据自身配置信息作出响应。

接收函数中主体循环的逻辑为：

- 等待并接收每一个包，直到以下事件之一发生，否则将收到的包根据 `btcp_seq` 序号放入暂存区（接收窗口）
  - 发送端指示发完了，即收到一个 `win_size = 0` 的包
  - 本地的暂存区满了
  - 超时没收到包（使用接收超时）
- 收到的数据包如果遇到以下情况之一会被丢弃，而不是放入暂存区
  - `btcp_seq` 序号所指示的数据包已存在于暂存区中
  - 该包含有错误的 `data_off` 或 `data_len`
- 整理收到的数据包，将连续的数据包存入接收数据（即函数的 `data` 参数），然后移进窗口，并统计缺失的数据包。若有缺失的数据包，则发回的 ACK 包中会通过 `btcp_ack` 和 `win_size` 指示发送端将缺失的包发来，实现选择重传 (SR)
- 若收到长度为零的包或接收数据区已存入足够的数据（通过函数的 `len` 参数指定），退出循环并清理

## 3.4 主程序逻辑

主程序负责处理命令行参数（使用 getopt 库灵活处理）并实际创建连接和发送/接收数据。命令行参数的用法可以通过 `btsend --help` 或 `btrecv --help` 命令查看，支持指定地址、端口等，其中文件名必须给出。

为了减少内存使用，同时由于后端 backTCP 也支持，文件将以 64 KiB 的块大小读入，按块发送或接收。

## 3.5 优点与不足

### 优点

- 能够可靠地处理丢包与乱序问题
- 支持选择重传（请加分）
- 实现方式为前后端分离，后端代码可以单独编译成库并在其他程序中调用（可以编译出 `libbtcp.so` 动态链接，尽管目前的 `Makefile` 并没有指出如何编译，但是经测试这是可以正常使用的）
- 支持在一个“连接”中多次调用发送/接收函数

### 缺点

- 命令行功能有限，例如不支持修改 backTCP 的属性等
- 窗口滑动采用 memmove(3) 而不是只修改索引，效率较低
- 前端程序仅支持单个函数的发送接收
- 部分异常未良好处理
- 指示关闭连接的 0 字节 UDP 包若丢包，会导致接收端无限等待（因此测试信道看到这个包就会原样转发，绕过“捣乱”逻辑）

## 3.6 测试信道实现 [<i class='fab fa-github'></i>](https://github.com/iBug/TetrisAI/releases/latest)

既然公开的测试信道是我写的，我就在这把它当做我提交的实验的一部分吧。

测试信道为了方便，使用 Python 语言编写，通过序列化 `BTcpPacket.__bytes__` 和反序列化 `@staticmethod BTcpPacket.from_bytes` 来在二进制序列和 `BTcpPacket` 类之间转换，同时使用 `argparse` 库提供丰富的命令行选项。

该程序在解析完命令行参数后，首先创建一个额外的线程将接收端返回的包原样转发给发送端，这是因为实验文档中（还是助教，我也忘了）说明了 ACK 包不会丢包。然后从一系列“动作”中随机选择一个，从发送端接收数据包并执行抽中的动作。目前测试信道支持以下 4 种动作：

- 什么都不做，直接转发给接收端
- 将包丢弃，除非包头指示该包为重传，此时什么都不做并转发
- 一次性接收两个包并将它们交换顺序后发出
- 一次性接收三个包，随机化它们的顺序，并随机复制或丢弃一个包。重传的包不会被复制或丢弃

若收到 0 字节的 UDP 包，则停止动作并将所有已收到的包发给接收端，然后关闭

# 四、结果展示

## 4.1 系统环境与编译

![](/image/backTCP/1.png)

## 4.2 直接传输

![](/image/backTCP/2.png)

![](/image/backTCP/3.png)

## 4.3 经过测试信道传输

![](/image/backTCP/4.png)

![](/image/backTCP/5.png)

## 4.5 结论

根据控制台输出，可以看到，不论是直接传输还是经过测试信道“捣蛋”时的传输，都可以完整传输一个 150 KB 的文件。在有测试信道时，发送端和接收端都能正确检测丢包和乱序，并采取合适的措施确保接收到的数据块是完整的。同时接收端也能够使用 ACK 包头中的信息，让发送端仅传回丢失的包，然后从缓冲区中恢复完整的书架序列，说明选择重传的功能也正确工作。
