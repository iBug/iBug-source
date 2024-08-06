---
title: "Wolfram Mathematica 13 Key Generator Online"
description: "Another JavaScript project"
tagline: ""
categories: life
tags: keygen
redirect_from: /p/19
noindex: true
toc: false
---

<p class="notice--primary">As iBug no longer uses Mathematica himself, this keygen will not be updated or maintained anymore.</p>

This page provides:

- Wolfram Mathematica 11 Key Generator
- Wolfram Mathematica 12 Key Generator
- Wolfram Mathematica 13 Key Generator
- Wolfram System Modeler 12 Key Generator
- Wolfram System Modeler 13 Key Generator

{% include airport.html %}

<div class="form-inline">
<p style="margin-bottom: 0;">Select product:</p>
<input type="radio" id="product-mma12" name="product" value="mma12">
<label for="product-mma12">Mathematica 11/12</label><br>
<input type="radio" id="product-mma13" name="product" value="mma13" checked>
<label for="product-mma13">Mathematica 13</label><br>
<input type="radio" id="product-sm" name="product" value="sm12">
<label for="product-sm">System Modeler 12/13</label>
</div>

Enter your MathID below and press **Generate**.

<input type="text" id="mathId" placeholder="xxxx-xxxxx-xxxxx" />

<button id="generate" class="btn btn--primary">Generate</button>

<p id="result">Press <b>Generate</b>!</p>

<div><script data-ad-client="ca-pub-4203697973995702" async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"></script></div>

<div class="notice--warning" markdown="1">
#### <i class="fa fas fa-exclamation-circle"></i> Notice
{: .no_toc }

Someone appears to be *selling* these kinds of tools. This is immoral and evil.
</div>

<script type="text/javascript">
function f1(n, byte, c) {
    for (var bitIndex = 0; bitIndex <= 7; bitIndex++) {
        var bit = (byte >> bitIndex) & 1;
        if (bit + ((n - bit) & ~1) === n) {
            n = (n - bit) >> 1;
        } else {
            n = ((c - bit) ^ n) >> 1;
        }
    }
    return n;
}

function genPassword(str, hash) {
    for (var byteIndex = str.length - 1; byteIndex >= 0; byteIndex--) {
        hash = f1(hash, str.charCodeAt(byteIndex), 0x105C3);
    }
    var n1 = 0;
    while (f1(f1(hash, n1 & 0xFF, 0x105C3), n1 >> 8, 0x105C3) !== 0xA5B6) {
        if (++n1 >= 0xFFFF) {
            return "Error";
        }
    }
    n1 = Math.floor(((n1 + 0x72FA) & 0xFFFF) * 99999.0 / 0xFFFF);
    var n1str = ("0000" + n1.toString(10)).slice(-5);
    var temp = parseInt(n1str.slice(0, -3) + n1str.slice(-2) + n1str.slice(-3, -2), 10);
    temp = Math.ceil((temp / 99999.0) * 0xFFFF);
    temp = f1(f1(0, temp & 0xFF, 0x1064B), temp >> 8, 0x1064B);
    for (byteIndex = str.length - 1; byteIndex >= 0; byteIndex--) {
        temp = f1(temp, str.charCodeAt(byteIndex), 0x1064B);
    }
    var n2 = 0;
    while (f1(f1(temp, n2 & 0xFF, 0x1064B), n2 >> 8, 0x1064B) !== 0xA5B6) {
        if (++n2 >= 0xFFFF) {
            return "Error";
        }
    }
    n2 = Math.floor((n2 & 0xFFFF) * 99999.0 / 0xFFFF);
    var n2str = ("0000" + n2.toString(10)).slice(-5);
    return n2str[3] + n1str[3] + n1str[1] + n1str[0] + "-"
        + n2str[4] + n1str[2] + n2str[0] + "-"
        + n2str[2] + n1str[4] + n2str[1] + "::1";
}

function checkMathId(s) {
    if (s.length != 16)
        return false;
    for (let i = 0; i < s.length; i++) {
        if (i === 4 || i === 10) {
            if (s[i] !== "-")
                return false;
        } else {
            if ("0123456789".search(s[i]) < 0)
                return false;
        }
    }
    return true;
}

function genActivationKey() {
    s = "";
    for (let i = 0; i < 14; i++) {
        s += Math.floor(Math.random() * 10);
        if (i === 3 || i === 7)
            s += "-";
    }
    return s;
}

document.getElementById("generate").addEventListener("click", function () {
    var mathId = document.getElementById("mathId").value.trim();
    if (!checkMathId(mathId)) {
        document.getElementById("result").innerText = "Bad MathID!";
    } else {
        var activationKey = genActivationKey();
        var magicNumbers;
        var software = document.querySelector("input[name=product]:checked").value;
        if (software === "mma12" || software === "mma13") {
            magicNumbers = [10690, 12251, 17649, 24816, 33360, 35944, 36412, 42041, 42635, 44011, 53799, 56181, 58536, 59222, 61041];
        } else if (software === "sm12") {
            magicNumbers = [4912, 4961, 22384, 24968, 30046, 31889, 42446, 43787, 48967, 61182, 62774];
        } else {
            document.getElementById("result").innerHTML = `<p>Unknown software suite: ${software}.</p>`;
            return;
        }
        var magicNumber = magicNumbers[Math.floor(Math.random() * magicNumbers.length)]
        var password = genPassword(mathId + "$1&" + activationKey, magicNumber);
        document.getElementById("result").innerHTML = `
        <p>
        <b>Activation Key</b>: ${activationKey}
        <br>
        <b>Password</b>: ${password}
        </p>
        <p>Thanks for using! Please consider purchasing the software if you find it helpful to you. We support genuine software.</p>
        `;
    }
});
</script>
