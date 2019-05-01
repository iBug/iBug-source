---
title: "Filter Manually Installed Packages from APT with AWK"
description: null
tagline: "How I replaced three text-processing commands with one"
tags: study-notes
redirect_from: /p/17

published: true
---

It's again when I want to find out what packages I have manually installed (or by a script) from the output of `apt list`, with all output on one line.

It's a pretty easy task if you're familiar with Unix command utilities for text manipulation, and you may probably have come up with this solution:

```shell
apt list |
grep -F '[installed]' |
cut -d/ -f1 |
tr '\n' ' '
echo
```

The last `echo` is there because the output from `tr` doesn't contain a newline at end, which would make your terminal look ugly. It's also not well-Unix-styled because all output should end with a newline.

I was in the middle of the desire to learn AWK when I faced this task, so I did some search and wrote this AWK script:

```awk
#!/usr/bin/awk -f
BEGIN {
  FS = "/"
  ORS = " "
}
/[installed]/ {
  print $1
}
END {
  ORS = "\n"
  print ""
}
```

Save this file as whatever name you like, apply `755` permissions and run `apt list | some.awk`, and watch the magic go.

# How's it done?

For those absolutely new to AWK, this is a good example to start with.

The first thing is blocks. Each block begins with a "match condition" that means the block will be executed when the condition matches. A condition can be a statement (like `$1 == "abcd"` or `NR % 2 == 0`), a regular expression (like the example abov) or a special pattern (`BEGIN` and `END`).

If the condition is a statement, it is evaluated and tested for truthness. If it's a regular expression, it's matched against the whole record. Special patterns are intuitive: before processing the first record (`BEGIN`) or after processing every record (`END`).

The second thing is statements. In the example, there are only two kinds of statements: `print` and variable assignments. `print` is plain (so far) and it prints whatever's after it. Here `$1` means the first field of the record.

The two assigned variables are [special][1]. `FS` stands for **F**ield **S**eparator and it's set to a slash, so the first field is everything before the first slash. `ORS` stands for **O**utput **R**ecord **S**eparator, and it's what `print` adds at the end of each `print` statement, much like the keyword variable `end` in Python 3's `print()` function.

More complex statements like conditions, loops and arithmetics are also possible, but I'm avoiding them here because they don't appear in this script.

Finally, it comes to the execution of the script. By default, `awk` takes the first non-option command-line argument as the AWK program to execute. To specify that the program is written in a file, you need the `-f` option, whence the [shebang line][2].

  [1]: https://www.gnu.org/software/gawk/manual/gawk.html#Built_002din-Variables
  [2]: https://en.wikipedia.org/wiki/Shebang_(Unix)
