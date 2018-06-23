---
title: "Pairing the new Xbox One S controller (2018) with Android"
tagline: "Finally, I got it to work"
description: "I just bought an Xbox One S controller that's manufactured in 2018. The `.kl` files found online weren't correct anymore so I had to dig it out by myself."
tags: gaming
redirect_from: /p/9
---

I just bought an Xbox One S controller yesterday, expecting it would pair with my Android phone via Bluetooth. I have learned that the key mapping would be a bit messed up because it's a Microsoft product, and have already prepared for it by downloading a key layout file and placing it in my phone. However, it seems more stuff has changed since the tutorials found online were published.

# Meeting the new controller

![Xbox One S controller][img]

# Configuring the new controller to play with Android

It is unarguably delighting that the new Xbox One S controller pairs with Android devices, but again, unfortunately, as [reviews][1] have shown, it doesn't play well. While [workarounds are easily available][2], those don't work for me, probably because my controller is too new (manufactured in April 2018).

The supplied keylayout file looks like below:

```sh
key 304   BUTTON_A
key 305   BUTTON_B
key 306   BUTTON_X
key 307   BUTTON_Y
key 308   BUTTON_L1
key 309   BUTTON_R1
key 310   BACK
key 311   BUTTON_START 
key 139   HOME
key 312   BUTTON_THUMBL
key 313   BUTTON_THUMBR

# Left and right stick.
axis 0x00 X flat 4096
axis 0x01 Y flat 4096
axis 0x03 Z flat 4096
axis 0x04 RZ flat 4096

# Triggers.
axis 0x02 LTRIGGER
axis 0x05 RTRIGGER

# Hat.
axis 0x10 HAT_X
axis 0x11 HAT_Y
```

Sadly, it has messed up on my phone. Button Y acts like button X, while button X doesn't function at all.

This small issue shouldn't be a problem for me, as has never been. With the help of Gamepad Tester applications, I worked out another keylayout file as following:

```sh
# XBox One S Controller (2018)
key 304   BUTTON_A
key 305   BUTTON_B
key 307   BUTTON_X
key 308   BUTTON_Y
key 310   BUTTON_L1
key 311   BUTTON_R1
key 315   BUTTON_START 
key 158   BUTTON_SELECT
key 317   BUTTON_THUMBL
key 318   BUTTON_THUMBR

# Left and right stick.
axis 0x00 X
axis 0x01 Y
axis 0x0b Z
axis 0x0e RZ

# Triggers.
axis 0x17 LTRIGGER
axis 0x17 BRAKE
axis 0x16 RTRIGGER
axis 0x16 THROTTLE

# Hat.
axis 0x0f HAT_X
axis 0x10 HAT_Y
```

If you're encountering the same problem even after trying solutions found online, try mine. Replace the file content with my one, restart your device and connect the controller again. It should work then.


  [img]: /image/xb1s-con.jpg
  [1]: https://www.androidpolice.com/2016/08/11/psa-the-new-bluetooth-enabled-xbox-one-controller-works-with-android-but-not-very-well/
  [2]: https://www.howtogeek.com/329647/how-to-get-the-xbox-one-s-controller-working-properly-with-android/
