---
title: "Programming the On-Board SPI Flash of Digilent Nexys4 DDR"
description: "A way to permanently write your Verilog design to the Nexys4 DDR board, so you can bring it wherever you like, as long as you have power supply. No more need for Vivado software."
tagline: "Standalone demo board, yay!"
tags: development study-notes
redirect_from: /p/13

show_view: false
view_name: "Stack Overflow"
view_url: "https://stackoverflow.com"
show_download: false
download_name: "Stack Overflow"
download_url: "https://stackoverflow.com"

published: true
---

This semester I have the course "Experiments of Digital Circuits", the content of which is designing digital circuits using Vivado software, and writing Verilog code. Most of the lab papers require generating bitstream for the project and downloading it to Nexys4 DDR board to verify the functionality. Most of the times we just sit in front of the computer, with the board plugged in, and downloading the bitstream.

The downloaded bitstream is volatile, so whenever the board loses its power, or the "PROG" button is pressed, the program is lost and instead, the out-of-box demo program is loaded from the SPI flash.

[Here](https://reference.digilentinc.com/learn/programmable-logic/tutorials/nexys-4-ddr-programming-guide/start#programming_the_nexys4-ddr_using_quad_spi) is Digilent's tutorial about how to program the SPI flash (i.e. replacing the OOB demo program).

<!--
For an easier guide, here's how I did it:

TBA
-->
