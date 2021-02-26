---
title: "Wolfram Mathematica 12 Key Generator Online"
description: "Another JavaScript project"
tagline: ""
categories: keygen
tags: keygen
redirect_from: /p/19
toc: false
---

### Supports Wolfram Mathematica 12.x

This includes 12.0, 12.1, 12.2 and any future version that begins with 12.

<div class="notice--warning" markdown="1">
#### <i class="fa fas fa-exclamation-circle"></i> Notice
{: .no_toc }

Does **not** work for other Wolfram products (e.g. Wolfram Player). It's for Mathematica only!
</div>

**Update 1 (April 20, 2020)**: I have examined Mathematica 12.1. No update is required. This utility is automatically compatible with Mathematica 12.1.

Input your MathID (xxxx-xxxxx-xxxxx) and press **Generate**.

<input type="text" id="mathId" placeholder="xxxx-xxxxx-xxxxx" />

<button id="generate" class="btn btn--primary">Generate</button>

<p id="result">Press <b>Generate</b>!</p>

<script data-ad-client="ca-pub-4203697973995702" async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"></script>

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
    return n2str.charAt(3) + n1str.charAt(3) + n1str.charAt(1) + n1str.charAt(0) + "-"
        + n2str.charAt(4) + n1str.charAt(2) + n2str.charAt(0) + "-"
        + n2str.charAt(2) + n1str.charAt(4) + n2str.charAt(1) + "::1";
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

Array.prototype.getRandom = function () {
    return this[Math.floor(Math.random() * this.length)];
}
document.getElementById("generate").addEventListener("click", function () {
    var mathId = document.getElementById("mathId").value.trim();
    if (!checkMathId(mathId)) {
        document.getElementById("result").innerText = "Bad MathID!";
    } else {
        var activationKey = genActivationKey();
        var magicNumbers;
        var software = "mma";
        if (software === "mma") {
            // Mathematica 12
            magicNumbers = [10690, 12251, 17649, 24816, 33360, 35944, 36412, 42041, 42635, 44011, 53799, 56181, 58536, 59222, 61041];
        } else if (software === "sm") {
            // SystemModeler 12
            magicNumbers = [4912, 4961, 22384, 24968, 30046, 31889, 42446, 43787, 48967, 61182, 62774];
        }
        var password = genPassword(mathId + "$1&" + activationKey, magicNumbers.getRandom());
        document.getElementById("result").innerHTML = `
        <p>
        <b>Activation Key</b>: ${activationKey}
        <br>
        <b>Password</b>: ${password}
        </p>
        <p>Don't forget to share your feelings below. Thanks for using!</p>
        <p><a href="http://raboninco.com/1wNoI">See an advert</a> if you want to support me!</p>
        `;
    }
});
</script>
