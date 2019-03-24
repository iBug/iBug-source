---
layout: post
title: Chisel 配置及入门
tagline: "从配置到生成 Verilog"
tags: study-notes
---

Chisel (Constructing Hardware In a Scala Embedded Language) 是一种嵌入在高级编程语言 Scala 的硬件构建语言。Chisel 实际上只是一些特殊的类定义，预定义对象的集合，使用 Scala 的用法，所以在写 Chisel 程序时实际上是在写 Scala 程序。

## 1. 系统需求

- Java 运行环境
- Scala
  - SBT (Simple Build Tool)

## 1.A Windows 环境配置

### 1.A.1 安装 Java

Java 的安装并不困难，也不需要额外的操作。直接从 Oracle 官网下载一个合适的 JDK 安装包，运行安装即可。这里我选择的版本是 JDK 8 Update 191。

- [下载 JDK 8u191 Windows 32位](https://download.oracle.com/otn-pub/java/jdk/8u191-b12/2787e4a523244c269598db4e85c51e0c/jdk-8u191-windows-i586.exe)
- [下载 JDK 8u191 Windows 64位](https://download.oracle.com/otn-pub/java/jdk/8u191-b12/2787e4a523244c269598db4e85c51e0c/jdk-8u191-windows-x64.exe)

安装过程直接点击 \[下一步\] 直到完成即可。

### 1.A.2 安装 Scala 及 SBT

Scala 是一门运行在 Java 上的语言，其编译器和工具链等都以 JAR 形式提供，因此不区分系统版本。SBT (Simple Build Tool) 是一个简单的 Scala 项目构建工具。Chisel 使用 SBT 来构建工程。对于 Windows 系统来说，只需要一个统一的安装包即可。编写本文时，SBT 的最新版本为 1.2.7，可以通过以下链接下载。

- [下载 SBT 1.2.7 Windows](https://piccolo.link/sbt-1.2.7.msi)

SBT 的安装也不复杂，双击 msi 安装包，一路点击 \[下一步\] 即可。

虽然不是必要的，但是建议在安装完 SBT 之后重启一下电脑。

### 1.A.3 准备 Chisel 依赖

安装好 SBT 之后，我们所有的准备工作都将借助 SBT 完成。

首先解压附件 `chisel-101.tar.gz` 并打开文件夹 `chisel-101`，然后在该文件夹中打开命令提示符。Windows 7 下可以按住 Shift 键并在文件夹空白处点右键，此时的菜单中会有 “在此处打开命令提示符” 的选项，如图：

![Open Command Prompt here](/image/chisel-intro/open-cmd.png)

在打开的命令提示符中输入 `sbt run`，确保网络通畅，等待 SBT 工具下载所需的依赖。由于众所周知的原因，在国内下载很慢，并且有可能中断，需要耐心重试。如果一切顺利，SBT 会完成所需的全部依赖，然后编译样例代码并运行。参考截图如下：

![SBT Run](/image/chisel-intro/sbt-first-run.png)

## 1.B Linux 环境配置 (Ubuntu)

Ubuntu 资源丰富，配置起来十分简单。这里以 18.04 版本为例，配置过程全程使用终端命令。

```shell
echo "deb https://dl.bintray.com/sbt/debian /" | sudo tee -a /etc/apt/sources.list.d/sbt.list
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823
sudo apt-get update
sudo apt-get install default-jdk build-essential perl sbt
```

参考链接：[Installing sbt on Linux](https://www.scala-sbt.org/1.0/docs/Installing-sbt-on-Linux.html)

以上操作会添加 SBT 提供的 APT 源，然后刷新 APT 软件包列表，并安装 JDK, SBT 等需要的软件包。

接下来解包附件 `chisel-101.tar.gz` （见末尾），并利用 sbt 配置所需的依赖。这些依赖全部是 Java 软件包，因此过程十分简单。请确保网络畅通，由于众所周知的原因，在国内下载很慢，并且有可能中断，需要耐心重试。

```shell
tar zxvf chisel-101.tar.gz
cd chisel-101/
sbt run
```

如果一切顺利，SBT 会完成所需的全部依赖，然后编译样例代码 `hello.scala` 并运行。具体输出可以参考上面 Windows 7 系统中的截图。

## 2. 开始第一个 Chisel 工程并生成 Verilog 代码

保留好附件 `chisel-101.tar.gz` 或者解包出来的文件夹 `chisel-101`，后面我们会经常用到它。

请注意，本文不是教你如何编辑 Scala 或 Chisel 代码，而是关注 Verilog 的生成。由于未直接使用[官方的教程仓库](https://github.com/ucb-bar/chisel-tutorial)，因此避开了 Verilator 的依赖（它相当不好配置）。

### 2.1 第一个组合逻辑电路

用文本编辑器或者 IDE (例如 IntelliJ IDEA) 打开 `src/main/scala/example/hello.scala`，观察内容：

```scala
package example

object Hello {
  def main(args: Array[String]): Unit = {
    println("Hello, Chisel!")
  }
}
```

这是一个最简单的 Scala 程序，它只输出一行 `Hello, Chisel!`。这并不是我们要学习的 Chisel 代码，所以现在把这个文件删掉。

下面我们用一个简单的示例（组合逻辑电路）来展示 Chisel，以及生成 Verilog 文件。

```scala
package example

import chisel3._

class FullAdder extends Module {
  val io = IO(new Bundle {
    val a    = Input(UInt(1.W))
    val b    = Input(UInt(1.W))
    val cin  = Input(UInt(1.W))
    val sum  = Output(UInt(1.W))
    val cout = Output(UInt(1.W))
  })

  // Generate the sum
  val a_xor_b = io.a ^ io.b
  io.sum := a_xor_b ^ io.cin
  // Generate the carry
  val a_and_b = io.a & io.b
  val b_and_cin = io.b & io.cin
  val a_and_cin = io.a & io.cin
  io.cout := a_and_b | b_and_cin | a_and_cin
}
```

这就是一个 1 位全加器模块。把它放在 `src/main/scala/example/Main.scala` 里，然后我们来尝试编译（综合）：

还是在工程目录 (有 `build.sbt` 文件的那个地方) 打开命令提示符（或终端），输入 `sbt run` 开始编译。稍等片刻，就会发现编译失败了。最后几行的错误信息中可以看到这样的内容：

```shell
[error] java.lang.RuntimeException: No main class detected.
```

我们的样例代码只包含了电路模块，并没有一个 “主函数” 可以让 Scala 运行。

打开刚才的 `Main.scala` 文件，在文件后面追加这几行代码：

```scala
object ChiselExample extends App {
  chisel3.Driver.execute(args, () => new FullAdder)
}
```

再次在工程目录中运行 `sbt run`，观察输出，这时候整个项目应该能正常编译了。

也许细心的你已经发现目录中出现了 `FullAdder.v` 这样一个文件。没错，这就是生成的 Verilog 代码！赶紧打开看看：

```verilog
module FullAdder( // @[:@3.2]
  input   clock, // @[:@4.4]
  input   reset, // @[:@5.4]
  input   io_a, // @[:@6.4]
  input   io_b, // @[:@6.4]
  input   io_cin, // @[:@6.4]
  output  io_sum, // @[:@6.4]
  output  io_cout // @[:@6.4]
);
  wire  a_xor_b; // @[Main.scala 15:22:@8.4]
  wire  a_and_b; // @[Main.scala 18:22:@11.4]
  wire  b_and_cin; // @[Main.scala 19:24:@12.4]
  wire  a_and_cin; // @[Main.scala 20:24:@13.4]
  wire  _T_16; // @[Main.scala 21:22:@14.4]
  assign a_xor_b = io_a ^ io_b; // @[Main.scala 15:22:@8.4]
  assign a_and_b = io_a & io_b; // @[Main.scala 18:22:@11.4]
  assign b_and_cin = io_b & io_cin; // @[Main.scala 19:24:@12.4]
  assign a_and_cin = io_a & io_cin; // @[Main.scala 20:24:@13.4]
  assign _T_16 = a_and_b | b_and_cin; // @[Main.scala 21:22:@14.4]
  assign io_sum = a_xor_b ^ io_cin; // @[Main.scala 16:10:@10.4]
  assign io_cout = _T_16 | a_and_cin; // @[Main.scala 21:11:@16.4]
endmodule
```

虽然看起来十分机械化，但是生成的这个 Verilog 代码是可以放在其他软件 (如 Xilinx Vidado) 中综合的。

好了，我们的第一个样例就到这里，你已经知道怎么写 Chisel 代码并生成 Verilog 了。

### 2.2 第一个时序逻辑电路

我从网上的样例中选出了这个作为时序逻辑电路的示范

```scala
package example

import chisel3._

class EnableShiftRegister extends Module {
  val io = IO(new Bundle {
    val in    = Input(UInt(4.W))
    val shift = Input(Bool())
    val out   = Output(UInt(4.W))
  })
  val r0 = Reg(UInt())
  val r1 = Reg(UInt())
  val r2 = Reg(UInt())
  val r3 = Reg(UInt())
  when(reset.toBool) {
    r0 := 0.U(4.W)
    r1 := 0.U(4.W)
    r2 := 0.U(4.W)
    r3 := 0.U(4.W)
  } .elsewhen(io.shift) {
    r0 := io.in
    r1 := r0
    r2 := r1
    r3 := r2
  }
  io.out := r3
}
```

上一节中编写的 `Main.scala` 先放着别动，把上面的代码保存到另一个文件，例如 `src/main/scala/example/Sequential.scala` 中，我们来尝试编译：在命令提示符或者终端中运行 `sbt run`。当 SBT 运行完成之后，你肯定迫不及待地想看看 `EnableShiftRegister.v` 长什么样。不过这次你可能要失望了，因为这个文件并不存在。

怎么回事呢？

打开上一节的 `Main.scala`，观察内容：

```scala
object ChiselExample extends App {
  chisel3.Driver.execute(args, () => new FullAdder)
}
```

也许你已经发现了，是这个地方决定哪些模块要被编译。所以我们添加一行，让它也编译新的模块。现在代码看起来像这样：

```scala
object ChiselExample extends App {
  chisel3.Driver.execute(args, () => new FullAdder)
  chisel3.Driver.execute(args, () => new EnableShiftRegister)
}
```

好了，再次运行 `sbt run`，你就可以看到 `EnableShiftRegister.v` 了，它的内容应该是这样：

```verilog
module EnableShiftRegister( // @[:@3.2]
  input        clock, // @[:@4.4]
  input        reset, // @[:@5.4]
  input  [3:0] io_in, // @[:@6.4]
  input        io_shift, // @[:@6.4]
  output [3:0] io_out // @[:@6.4]
);
  reg [3:0] r0; // @[Sequential.scala 11:15:@8.4]
  reg [31:0] _RAND_0;
  reg [3:0] r1; // @[Sequential.scala 12:15:@9.4]
  reg [31:0] _RAND_1;
  reg [3:0] r2; // @[Sequential.scala 13:15:@10.4]
  reg [31:0] _RAND_2;
  reg [3:0] r3; // @[Sequential.scala 14:15:@11.4]
  reg [31:0] _RAND_3;
  wire [3:0] _GEN_0; // @[Sequential.scala 20:25:@20.6]
  wire [3:0] _GEN_1; // @[Sequential.scala 20:25:@20.6]
  wire [3:0] _GEN_2; // @[Sequential.scala 20:25:@20.6]
  wire [3:0] _GEN_3; // @[Sequential.scala 20:25:@20.6]
  assign _GEN_0 = io_shift ? io_in : r0; // @[Sequential.scala 20:25:@20.6]
  assign _GEN_1 = io_shift ? r0 : r1; // @[Sequential.scala 20:25:@20.6]
  assign _GEN_2 = io_shift ? r1 : r2; // @[Sequential.scala 20:25:@20.6]
  assign _GEN_3 = io_shift ? r2 : r3; // @[Sequential.scala 20:25:@20.6]
  assign io_out = r3; // @[Sequential.scala 26:10:@26.4]
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE
  integer initvar;
  initial begin
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      #0.002 begin end
    `endif
  `ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  r0 = _RAND_0[3:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_1 = {1{`RANDOM}};
  r1 = _RAND_1[3:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_2 = {1{`RANDOM}};
  r2 = _RAND_2[3:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_3 = {1{`RANDOM}};
  r3 = _RAND_3[3:0];
  `endif // RANDOMIZE_REG_INIT
  end
`endif // RANDOMIZE
  always @(posedge clock) begin
    if (reset) begin
      r0 <= 4'h0;
    end else begin
      r0 <= _GEN_0;
    end
    if (reset) begin
      r1 <= 4'h0;
    end else begin
      r1 <= _GEN_1;
    end
    if (reset) begin
      r2 <= 4'h0;
    end else begin
      r2 <= _GEN_2;
    end
    if (reset) begin
      r3 <= 4'h0;
    end else begin
      r3 <= _GEN_3;
    end
  end
endmodule
```

注意到，由于 Chisel 语言只有 0/1，不支持三态或者高阻态，所以这里对几个寄存器采取了随机初始化的办法。另外也可以看到，尽管模块中没有声明时钟 `clock` 和重置 `reset` 信号，但是所有编译出来的 Verilog 代码都会包含这两个输入，并且在有需要的时候向嵌套的模块传递，这可以在下面这个示例中观察到。

### 2.3 嵌套模块

这次我们使用前面编写的 1 位全加器来构建一个多位全加器

```scala
package example

import chisel3._

class Inner extends Module {
  val io = IO(new Bundle {
    val dataIn  = Input(UInt(1.W))
    val dataOut = Output(UInt(1.W))
  })
  val data = RegNext(io.dataIn)
  io.dataOut := data
}

class Outer extends Module {
  val io = IO(new Bundle {
    val dataIn  = Input(UInt(1.W))
    val dataOut = Output(UInt(1.W))
  })
  val core = Module(new Inner()).io
  core.dataIn := io.dataIn
  io.dataOut := core.dataOut
}
```

把以上内容保存为 `src/main/scala/example/Nested.scala`。同样，我们要修改 `Main.scala`，使它编译新的 `Outer` 模块。

```scala
object ChiselExample extends App {
  chisel3.Driver.execute(args, () => new Outer)
}
```

运行 `sbt run`，然后观察生成的 `Outer.v`。可以发现，Chisel 自动将 `clock` 从模块 `Outer` 传递到了模块 `Inner`。

```verilog
module Inner( // @[:@3.2]
  input   clock, // @[:@4.4]
  input   io_dataIn, // @[:@6.4]
  output  io_dataOut // @[:@6.4]
);
  reg  data; // @[Nested.scala 10:21:@8.4]
  reg [31:0] _RAND_0;
  assign io_dataOut = data; // @[Nested.scala 11:14:@10.4]
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE
  integer initvar;
  initial begin
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      #0.002 begin end
    `endif
  `ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  data = _RAND_0[0:0];
  `endif // RANDOMIZE_REG_INIT
  end
`endif // RANDOMIZE
  always @(posedge clock) begin
    data <= io_dataIn;
  end
endmodule
module Outer( // @[:@12.2]
  input   clock, // @[:@13.4]
  input   reset, // @[:@14.4]
  input   io_dataIn, // @[:@15.4]
  output  io_dataOut // @[:@15.4]
);
  wire  Inner_clock; // @[Nested.scala 19:20:@17.4]
  wire  Inner_io_dataIn; // @[Nested.scala 19:20:@17.4]
  wire  Inner_io_dataOut; // @[Nested.scala 19:20:@17.4]
  Inner Inner ( // @[Nested.scala 19:20:@17.4]
    .clock(Inner_clock),
    .io_dataIn(Inner_io_dataIn),
    .io_dataOut(Inner_io_dataOut)
  );
  assign io_dataOut = Inner_io_dataOut; // @[Nested.scala 21:14:@21.4]
  assign Inner_clock = clock; // @[:@18.4]
  assign Inner_io_dataIn = io_dataIn; // @[Nested.scala 20:15:@20.4]
endmodule
```

### 2.4 关于多个主函数 (Scala 入口)

有时候你并不需要一次编译全部代码，而反复修改 `Main.scala` 中的那个 `object` 又较为麻烦，那有什么办法简化这种工作吗？就像 Make 可以指定目一样。

方法是，编写多个 “主函数”，然后按需选择入口。例如

```scala
object Main extends App {
  chisel3.Driver.execute(args, () => new FullAdder)
}

object Sequential extends App {
  chisel3.Driver.execute(args, () => new EnableShiftRegister)
}

object Nested extends App {
  chisel3.Driver.execute(args, () => new Outer)
}
```

请注意，这时候由于我们有三个入口，因此直接运行 `sbt run` 的时候将无法编译。我们需要指定一个入口：

```shell
sbt run Sequential
```

运行上面的命令后，可以看到模块 `EnableShiftRegister` 被编译，生成了 `EnableShiftRegister.v`，而其他模块并没有生成对应的 Verilog 文件。

好了，关于生成 Verilog 代码就到这里了。

---

更多样例代码可以在 GitHub 仓库 [chisel-tutorial](https://github.com/ucb-bar/chisel-tutorial) 中找到。

# 附录

- 附件 `chisel-101.tar.gz` 下载： <https://github.com/iBug/Archive/releases/download/Release/chisel-101.tar.gz>
- 包含三个样例代码的 `chisel-101-with-examples.tar.gz` 下载： <https://github.com/iBug/Archive/releases/download/Release/chisel-101-with-examples.tar.gz>

- Chisel 官方网站： <https://chisel.eecs.berkeley.edu/>
- GitHub 教程仓库： <https://github.com/freechipsproject/chisel3/>
