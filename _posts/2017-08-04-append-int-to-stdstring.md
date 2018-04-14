---
title: Append int to std::string
description: Some confusion about templates in C++
tagline: A Stack Overflow question & answer
date: 2017-08-04 11:35:05Z
tags: stack-overflow development
show_view: true
view_name: Stack Overflow
view_url: https://stackoverflow.com/a/45505795/5958455
redirect_from:
  - /p/1
---

For people new to template resolution and template type deduction in C++, they may have written this code and get confused why it doesn't compile:

```c++
#include <string>

int main()
{
    std::string s;
    s += 2;     // compiles correctly
    s = s + 2;  // compiler error
    return 0;
}
```

And here's my answer:

---


**TL;DR** `operator+=()` is a class member function in class `string`, while `operator+()` is a template function.

The standard class `template<typename CharT> basic_string<CharT>` has an overloaded member function `basic_string& operator+=(CharT)`, and string is just `basic_string<char>`.

As values that fits in a shorter type can be interpreted as that type, in the expression `s += 2`, the 2 is *not* treated as `int`, but `char` instead. It has *exactly* the same effect as `s += '\x02'`. A char with ASCII code 2 (STX) is appended, instead of the character `'2'` (with ASCII value 50, or 0x32).

However, string does not have an overloaded member function like `string operator+(int)`, so `s + 2` is not a valid expression, thus throws an error during compilation. (More below)

You can use operator+ function in string in these ways:

```c++
s = s + char(2);  // or (char)2
s = s + std::string(2);
s = s + std::to_string(2);  // C++11 and above only
```

---

For people concerned about why 2 isn't automatically cast to `char` with `operator+`,

```c++
template <typename CharT>
  basic_string<CharT>
  operator+(const basic_string<CharT>& lhs, CharT rhs);
```

The above is the prototype<sup>\[note]</sup> for the plus operator in `s + 2`, and because it's a template function, it is requiring an implementation of both `operator+<char>` and `operator+<int>`, which is conflicting. For details, see [Why isn't automatic downcasting applied to template functions?][1]

Meanwhile, the prototype of `operator+=` is:

```c++
template <typename CharT>
class basic_string{
    basic_string&
      operator+=(CharT _c);
};
```

You see, no template here (it's a class member function), so the compiler deduces that type `CharT` is `char` from class implementation, and `int(2)` is automatically cast into `char(2)`. 

  [1]: https://stackoverflow.com/q/45506372/5958455

---

<sup><b>Note:</b> Unnecessary code is stripped when copying from C++ standard include source. That includes typename 2 and 3 (Traits and Allocator) for template class "basic_string", and unnecessary underscores, in order to improve readability.</sup>
