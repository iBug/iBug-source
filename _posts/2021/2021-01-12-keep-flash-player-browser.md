---
title: "Keep using Flash Player in browsers in 2021"
categories: tech
tags: web windows
redirect_from: /p/39
---

It's 2021 now, and [Adobe Flash Player has been end-of-life][1] after December 31, 2020. There are many cases where you want to retain it, however. For example, you may want to keep enjoying an old game that's been around for decades, or managing your organization's infrastructure via [VMware vSphere Flash Web Client (vSphere 6.5 and older)][2].

## Quick Solution

According to [Adobe Flash Player 32.0 Administration Guide][3], page 28 and 36, you can deploy a config file named `mms.cfg` with the following content to continue using Flash on whitelisted sites:

```ini
EOLUninstallDisable=1
SilentAutoUpdateEnable=0
AutoUpdateDisable=1
EnableAllowList=1
AllowListUrlPattern=*://*.example.com/
AllowListUrlPattern=*://*.example.net/
AllowListUrlPattern=*://*.example.org/
AllowListUrlPattern=file:*

TraceOutputEcho=1
```

Depending on your operating system, the file may be located at:

- Windows: `C:\Windows\System32\Macromed\Flash` and `C:\Windows\SysWOW64\Macromed\Flash` (if you're on a 64-bit Windows)
- macOS: `/Library/Application Support/Macromedia`
- Linux: `/etc/adobe` (yes it *is* Adobe instead of Macromedia)

Placing the `mms.cfg` file inside the correct directory (both directories for 64-bit Windows) should enable Flash on websites you whitelisted.

Additionally, if you're using **Google Chrome** or Chromium-based **Microsoft Edge**, you need to place an additional `mms.cfg` file in the following directory:

- Windows: `C:\Users\<username>\AppData\Local\Google\Chrome\User Data\Default\Pepper Data\Shockwave Flash\System\mms.cfg`
- macOS: `/Users/<username>/Library/Application Support/Google/Chrome/Default/Pepper Data/Shockwave Flash/System`
- Linux: `~/.config/google-chrome/Default/Pepper Data/Shockwave Flash/System/`

For Microsoft Edge, replace `Google` with `Microsoft` and `Chrome` with `Edge` in the above paths. Don't forget to replace `<username>` with your user name.

After placing the `mms.cfg` file, just restart your browser to see Flash come back again.

## The Future

The Chromium browser (basis of Google Chrome and modern Microsoft Edge) [will completely remove Flash][4] since version 88, and [so will Firefox][5] since version 85. This means you can no longer enable Flash even with the above *Enterprise policy* applied.

Unfortunately, you have to keep an old version of your browser of choice around if you plan to use Flash for an extended period. This means you have to find an available download, and disable the auto-update feature for the browser. You will be missing the latest web features and security improvements if you [remain on an old browser][6], which will be an issue sooner or later.

You can get around the browser issue by using Internet Explorer if you're on Windows, which is *already* lacking new web features and security. You'll want to prevent Windows Update [KB4577586][7] from installing, following [Microsoft's guidelines][8].

A better approach is to keep the Flash Player installers around (I saved FP v29 [here][9] if you need - it's a full set so beware of download size - 421 MB), and install them when needed.

Finally, the only way to secure your ability to use Flash in the distant future is to install a virtual machine running an older system (like Windows 7), with old software and old browsers, and *then* put your Flash Player there.


  [1]: https://www.adobe.com/products/flashplayer/end-of-life.html
  [2]: https://kb.vmware.com/s/article/78589
  [3]: https://www.adobe.com/content/dam/acom/en/devnet/flashplayer/articles/flash_player_admin_guide/pdf/latest/flash_player_32_0_admin_guide.pdf
  [4]: https://www.chromium.org/flash-roadmap#TOC-Flash-Support-Removed-from-Chromium-Target:-Chrome-88---Jan-2021-
  [5]: https://developer.mozilla.org/en-US/docs/Plugins/Roadmap#schedule
  [6]: https://browser-update.org/
  [7]: https://www.catalog.update.microsoft.com/search.aspx?q=4577586
  [8]: https://support.microsoft.com/en-us/help/3183922/how-to-temporarily-prevent-a-windows-update-from-reinstalling-in-windo
  [9]: https://download.ibugone.com/fp_29.0.0.171_archive.zip