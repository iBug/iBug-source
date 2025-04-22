---
title: "Fixing OneDrive not expanding in Explorer sidebar on Windows 10 LTSC"
tags: windows
redirect_from: /p/75
---

I've recently re-installed Windows 10 LTSC for both of my computers, and after setting up OneDrive (from Office 365 suite), I noticed that the OneDrive folder in the Explorer sidebar was not expanding when clicked, showing a static gray arrow.
This *could* be a known issue with Windows 10 LTSC, as it doesn't include OneDrive integration by default, unlike consumer versions.

For readers who want to skip the details, just head to the [**Solution**](#solution) section.

## Gathering Information

Looking for "Windows 10 OneDrive doesn't expand" on Google, [One drive folder tab not expanding](https://answers.microsoft.com/en-us/msoffice/forum/all/one-drive-folder-tab-not-expanding/04eac1d9-2665-4c5e-b02b-9976fbcf2c49) shows up first.
It contains no useful information other than a link to another: [Cannot access Onedrive - Personal folder through Quick Access of File Explorer](https://answers.microsoft.com/en-us/windows/forum/all/cannot-access-onedrive-personal-folder-through/fb21a27c-bf5a-4371-926e-9ff869070f03).

The second link is much better populated with information, notably there's a valid workaround:

> ```ini
> Windows Registry Editor Version 5.00
>
> [HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\Instance\InitPropertyBag]
> "TargetKnownFolder"=""
>
> [HKEY_CLASSES_ROOT\WOW6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\Instance\InitPropertyBag]
> "TargetKnownFolder"=""
> ```
>
> Save them as a .reg file, run it each time you log on (and after One Drive running)

Note how this needs to be applied every time OneDrive starts, which is something to further investigate.

With a bit more trying and Googling, it turns out OneDrive sets these keys to `{a52bba46-e9e1-435f-b3d9-28daa648c0f6}`, which is the KnownFolderID for the OneDrive folder, and is missing from the registry.

From the two `bbs.pcbeta.com` links (Chinese: 远景论坛, [1](https://bbs.pcbeta.com/viewthread-1933367-2-2.html) #32, [2](https://bbs.pcbeta.com/viewthread-1936542-1-2.html) #17) mentioned in the thread, adding back the missing registry keys for `{a52bba46-e9e1-435f-b3d9-28daa648c0f6}` should fix the issue.

## Solution

Just import the missing registry keys for OneDrive.
These registry keys are exported from a working Windows 10 Enterprise installation.

```ini
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{A52BBA46-E9E1-435f-B3D9-28DAA648C0F6}]
"Attributes"=dword:00000001
"Category"=dword:00000004
"DefinitionFlags"=dword:00000040
"Icon"=hex(2):25,00,53,00,79,00,73,00,74,00,65,00,6d,00,52,00,6f,00,6f,00,74,\
  00,25,00,5c,00,73,00,79,00,73,00,74,00,65,00,6d,00,33,00,32,00,5c,00,69,00,\
  6d,00,61,00,67,00,65,00,72,00,65,00,73,00,2e,00,64,00,6c,00,6c,00,2c,00,2d,\
  00,31,00,30,00,34,00,30,00,00,00
"LocalizedName"=hex(2):40,00,25,00,53,00,79,00,73,00,74,00,65,00,6d,00,52,00,\
  6f,00,6f,00,74,00,25,00,5c,00,53,00,79,00,73,00,74,00,65,00,6d,00,33,00,32,\
  00,5c,00,53,00,65,00,74,00,74,00,69,00,6e,00,67,00,53,00,79,00,6e,00,63,00,\
  43,00,6f,00,72,00,65,00,2e,00,64,00,6c,00,6c,00,2c,00,2d,00,31,00,30,00,32,\
  00,34,00,00,00
"LocalRedirectOnly"=dword:00000001
"Name"="OneDrive"
"ParentFolder"="{5E6C858F-0E22-4760-9AFE-EA3317B67173}"
"ParsingName"="shell:::{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
"RelativePath"="OneDrive"

[HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{A52BBA46-E9E1-435f-B3D9-28DAA648C0F6}]
"Attributes"=dword:00000001
"Category"=dword:00000004
"DefinitionFlags"=dword:00000040
"Icon"=hex(2):25,00,53,00,79,00,73,00,74,00,65,00,6d,00,52,00,6f,00,6f,00,74,\
  00,25,00,5c,00,73,00,79,00,73,00,74,00,65,00,6d,00,33,00,32,00,5c,00,69,00,\
  00,31,00,30,00,34,00,30,00,00,00
"LocalizedName"=hex(2):40,00,25,00,53,00,79,00,73,00,74,00,65,00,6d,00,52,00,\
  6f,00,6f,00,74,00,25,00,5c,00,53,00,79,00,73,00,74,00,65,00,6d,00,33,00,32,\
  00,5c,00,53,00,65,00,74,00,74,00,69,00,6e,00,67,00,53,00,79,00,6e,00,63,00,\
  43,00,6f,00,72,00,65,00,2e,00,64,00,6c,00,6c,00,2c,00,2d,00,31,00,30,00,32,\
  00,34,00,00,00
"LocalRedirectOnly"=dword:00000001
"Name"="OneDrive"
"ParentFolder"="{5E6C858F-0E22-4760-9AFE-EA3317B67173}"
"ParsingName"="shell:::{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
"RelativePath"="OneDrive"
```

Note that this article happens to reproduce [this blog](https://lolicp.com/windows/202309626.html) from lolicp.com, which may be of Chinese readers' interest.
