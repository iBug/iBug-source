---
title: "Wolfram Mathematica 12 Key Generator"
description: "Another JavaScript project"
tagline: ""
tags: keygen
redirect_from: /p/19

published: true
---

**Supports Wolfram Mathematica 12.0**

Input your MathID (xxxx-xxxxx-xxxxx) and press **Generate**.

<input type="text" id="mathId"/>

<button id="generate">Generate</button>

<p id="result">Press <b>Generate</b>!</p>

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

Array.prototype.getRandom = function () {
    return this[Math.floor(Math.random() * this.length)]
}
document.getElementById("generate").addEventListener("click", function () {
    document.getElementById("result").innerText = "";
    var mathId = document.getElementById("mathId").value.trim();
    if (!checkMathId(mathId)) {
        document.getElementById("result").innerText = "Bad MathID!";
    } else {
        activationKey = "";
        for (let i = 0; i < 14; i++) {
            activationKey += Math.floor(Math.random() * 10);
            if (i === 3 || i === 7)
                activationKey += "-";
        }
        var magicNumbers = [10690, 12251, 17649, 24816, 33360, 35944, 36412, 42041, 42635, 44011, 53799, 56181, 58536, 59222, 61041];
        var password = genPassword(mathId + "$1&" + activationKey, magicNumbers.getRandom());
        document.getElementById("result").innerText += "Activation Key: " + activationKey + "\nPassword: " + password;
    }
});
</script>
