---
title: "Raspberry Pi 4 B Review and Benchmark - What's improved over Pi 3 B+"
tags: raspberry-pi review benchmark
redirect_from: /p/26

published: false
---

Lately I've finally received my Raspberry Pi 4 (4 GB model), and I couldn't resist the temptation to give it a try and see all the improvements that's been reported for months.

As I've got one with my Pi 3 B+, I also ordered an aluminum "case" that can ease the ache of heating. One major difference is that the new cooling case is armed with two little fans, which is a rather huge boost in speed of heat dissipation.

So let's take a look at the new Pi 4.

## Overview

The new Pi 4 is wrapped in a box similar to that of Pi 3 B+, with a white outline of the Pi 4 in 1:1 scale on a red background. Unlike Pi 3 B, neither 3 B+ and 4 has a electrostatic-proof bag around them in the box. This isn't anything of a problem, though.

The new Pi 4 has a similar form factor as its predecessors, with a few noticeable differences, among which the USB 3.0 ports is the first to spot, as they're marked blue. As you inspect the USB 3.0 ports, you probably have noticed that the Ethernet port changed its position as well, which is likely due to the upgrade to a true gigabit port.

Some smaller ports, namely the power supply and the video output, have changed as well. The Pi 4 now requires a Type-C cable for power, and the requirement has raised to 5V / 3A. It's unknown whether the Pi 4 accepts advanced charging protocols like Qualcomm Quick Charge or USB PD, but user reports goes against such assumptions. The standard-size HDMI on older models has also been replaced by micro-HDMI port, pardon, *ports*. Yes, there are two, and both of them supports 4K @ 60 fps output, at the same time. While I'm planning to use this Pi as a headless server, people who use it as a desktop may find it favorable.

The RAM chip has also been moved from the back of the board to the front, alongside the SoC, which has an identical look as that on Pi 3 B+, but with a completely different heart under the skins. The Wi-Fi case and antenna remain unchanged, and there's an extra chip in front of the gigabit ethernet port.

## Specs

It's an exciting news that the new Pi 4 brings a wire range of solid and concrete upgrades, namely

- Broadcom BCM2711 SoC, quad-core Cortex-A72 CPU @ 1.5 GHz
- Comes in variations of 1 GB, 2 GB and **4 GB RAM** (reviewed)
- Broadcom VideoCore VI GPU
- True Gigabit ethernet port
- Bluetooth 5.0
- Native USB 3.0 interface, with two Type-A ports
- Dual HDMI port, supporting 4K @ 60 fps simultaneously
- Faster microSD card slot

In later benchmarks, you'll see what these upgrades really mean. Here's a table for comparison:

| Item      |                Pi 3 B                |               Pi 3 B+                |                     Pi 4                     |
| --------- | :----------------------------------: | :----------------------------------: | :------------------------------------------: |
| CPU       | Quad-core<br />Cortex-A53 @ 1.20 GHz | Quad-core<br />Cortex-A53 @ 1.40 GHz |     Quad-core<br />Cortex-A72 @ 1.50 GHz     |
| RAM       |              1 GB DDR2               |              1 GB DDR2               |            1 / 2 / **4** GB DDR4             |
| GPU       |             VideoCore IV             |             VideoCore IV             |                 VideoCore VI                 |
| Ethernet  |               100 Mbps               |          300 Mbps effective          |                    1 Gbps                    |
| Wi-Fi     |               2.4 GHz                |           2.4 GHz / 5 GHz            |               2.4 GHz / 5 GHz                |
| Bluetooth |                 4.0                  |                 4.2                  |                     5.0                      |
| USB       |             4 \* USB 2.0             |             4 \* USB 2.0             |         2 \* USB 2.0 + 2 \* USB 3.0          |
| Price     |                 \$35                 |                 \$35                 | \$35 / \$45 / **\$55**<br />Depending on RAM |

My Pi 3 B was sold soon after I got a 3 B+, so unfortunately there isn't one participating this review.

## My setup {#setup}

![Both Rasoberry Pis, powered through their GPIO pins](/image/rpi4/rpis-powered.jpg)

As seen above, both Pis are set up as headless servers, with only power and ethernet connected. You're probably wondering why they look so strange, which is because my laboratory provides a lot of these power supplies rated 5V / 6A, so I just took one and use it to power both Pis through GPIO. The two Pis are rated 5V / 2.5A and 5V / 3A each (peak), which this single power supply should be able to handle without difficulty.

> **WARNING**: Do NOT power your Raspberry Pi through GPIO unless you have stable power supply. Phone chargers aren't *power supplies* and should not be used to provide power in this way.

## Benchmarking

The Pis have static IP assigned and all operation is done over SSH. Operating system is latest Raspbian Buster Lite.

### 1. SysBench CPU test {#cpu}

SysBench is a benchmark suite that allows you to quickly get an impression of system performance. Here I use SysBench for CPU and Memory tests.

