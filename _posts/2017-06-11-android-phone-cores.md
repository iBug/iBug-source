---
title: Some ideas about multicore on Android
tagline: An Android Enthusiasts Q&A
description: Why do Android phones have more cores than computers?
date: 2017-06-11 10:51:16Z
tags: stack-exchange android
show_view: true
view_name: Android Enthusiasts
view_url: https://android.stackexchange.com/a/176503/205764
redirect_from:
  - /p/2
---

Laptops have usually at most four cores, and dualcores are probably more common. I have recently switched from quadcore to dualcore and I can confirm there is a limited number of use cases for quadcore, even with CPU intensive tasks.

On the other hand, on mobile phones, quadcores, hexacores and octacores seem to be common. Why? What tasks can utilize them?

---

First things first, **the [big.LITTLE][big-little] combination strategy** (technically, [**HMP**][hc], **Heterogeneous Multi-Processing** clusters) is the primary reason for so many (and sometimes overwhelmingly many) cores. A mobile device often runs into multiple scenarios, both heavy load and light load ones included.

An extreme consumer-class example is MediaTek's Helio X20, which has 2 performance-oriented A72 cores, 4 balanced A53 cores, plus 4 energy-efficient A35 cores. That's very flexible throughout different usage cases. However, I think <s>8 cores</s> 2 clusters is usually enough.

There's also another desktop-like example, Qualcomm's Snapdragon 800 series (S 800, S 801, and S 805). There are only 4 cores of the same microarchitecture in each SoC, with 2 clocked higher and 2 clocked lower. Qualcomm made these SoCs because they were very confident of their own microarchitecture (Krait 400 and Krait 450).

For games, even if they seemingly demand GPU performance rather than CPU, they still put a heavy load on the CPU. A GPU cannot work alone without something else supplying it with data to be processed, and that's one of the major jobs that the CPU is doing while you're gaming. In most gaming cases, the GPU only renders graphics, while all other jobs like loading data, resources and assets, and calculating in-game mechanics like the system, environment and physics are done by the  CPU. You won't observe a higher frame rate if you upgrade your GPU while sticking to a low-end CPU.

A secondary reason is **how Android utilizes CPU resources**. Android pretty much makes their own application environment. It uses nothing but codes (and APIs) from Java, but it has its own virtual machine named Dalvik, which was later replaced by ART (API Level 21). APKs have their executable codes in a "neutral" format, much like `.class` files in Java. Before they're run, the codes get compiled once more into the machine's native instructions<sup>\[1]</sup>. The compilation process is multi-threaded and can utilize multi-cores for a performance boost.  
And when an app is running, there are several other processes and mechanics (like the Garbage Collector) that run alongside, or parallel to the app. More cores can let the supportive processes run more efficiently, as well as the main app.  
<sub>1. If you use a file type identifier, you'll find that "optimized" dex files are in ELF format, while the "neutral" dex files are just in a format of their own.</sub>

Another lesser reason is that **ARM cores can't work as fast as an Intel x86 chip**. The Intel x86 microarchitecture can be dated back to 1976, when the [Intel 8086][intel-8086] chip started to be designed, which means that the x86 has developed over a long time. A single modern high-end ARM Cortex-A73 core is only as powerful as an Intel Clarkdale core, taking [Core i5-660][gb-i5-660] as an example (GeekBench, single-core). This is because x86 is a [CISC][cisc] microarchitecture while ARM is a [RISC][risc] microarchitecture. You surely don't want a phone that becomes laggy with only two or so active apps. More cores will help relieve the pressure. That's why dual-core SoCs are relatively popular only on smart watches. Who needs performance on a smart watch?

Interestingly, **more cores will result in less power than a single core at the same load**. The relationship between CPU frequency and power consumption is more than linear, so twice the frequency will always result in demanding more than twice, or even 3x or 4x as much power, while delivering less than twice the performance (due to other resource limitations like cache). So 4 cores can easily beat a single core at the same load, providing better performance and simultaneously demanding less power.

Further Reading:

- [Why 8 and 10 CPU cores in smartphones are a good idea – a lesson from the kitchen](http://www.androidauthority.com/why-8-and-10-cpu-cores-in-smartphones-are-a-good-idea-607894/)  
- [Why some phones have two quad core processors and some have similar clocked octa core. Which is better one in terms of performance?](https://www.quora.com/Why-some-phones-have-two-quad-core-processors-and-some-have-similar-clocked-octa-core-Which-is-better-one-in-terms-of-performance?share=1)  

  [big-little]: https://en.wikipedia.org/wiki/ARM_big.LITTLE
  [hc]: https://en.m.wikipedia.org/wiki/Heterogeneous_computing
  [intel-8086]: https://en.wikipedia.org/wiki/Intel_8086
  [cisc]: https://en.wikipedia.org/wiki/Complex_instruction_set_computer
  [risc]: https://en.wikipedia.org/wiki/Reduced_instruction_set_computer
  [gb-i5-660]: http://browser.primatelabs.com/geekbench3/search?q=i5-660
