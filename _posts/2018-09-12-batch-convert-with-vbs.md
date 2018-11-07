---
title: "Batch convert PowerPoint slideshow to PDF"
description: "It could be a nightmare to process 30+ files by hand, opening each one and then saving as PDF. But that nightmare was bypassed, with a VBScript."
tagline: "How scripting eases your work"
tags: development microsoft-office
redirect_from: /p/12

show_view: true
view_name: "GitHub"
view_url: "https://github.com/iBug/vbsGadgets/blob/master/AutoConvOffice/MassConv_PPTX-PDF.vbs"
show_download: false
download_name: "Stack Overflow"
download_url: "https://stackoverflow.com"
---

The **TL:DR** line: If you want my script, you can get it [here][1].

This semester my Physics teacher released all his PowerPoint slideshows at the start of the semester.
To make reading easier, I decided to convert all of them into 6-slide handouts and print them.
Fortunately, PowerPoint offers this functionality with the "Save as PDF" option, which could very well mean that I should open the 30+ files one-by-one and doing a "Save As" action on each one.
How painful!

That's apparently not an amateur programmer's flavor, so I decided to automate this process. I can write a script that will do all the repeated job for me.
Luckily, I wrote [another script][1] that converts `.ppt` to `.pptx` in batch. It's a good news that I can take this script directly, make minimal modification and put it into use.

So it begins. First I need to know how to save slideshow as PDF with VBA.
Going Googling, [this][2] is the first result that comes to me.
Quickly scanning through the post, I decided that this is the line of code that I want:

```vb
ActivePresentation.ExportAsFixedFormat CurrentFolder & FileName & ".pdf", _
  ppFixedFormatTypePDF, ppFixedFormatIntentPrint, msoCTrue, ppPrintHandoutHorizontalFirst, _
  ppPrintOutputSlides, msoFalse, , ppPrintAll, , False, False, False, False, False
```

Very good! I copied it, replaced the constants from what I found on Microsoft Office Documentation (VBScript doesn't have them), and gave the script a try.

Well, no. It didn't work and exited with an error dialog.

I spent 3 hours debugging and couldn't find out what's wrong. *Good documentations, Microsoft!* I went on for another hour searching Google for a solution, only to find out that `ExportAsFixedFormat` does not accept empty parameters.

I then fixed the issue and the script finally worked, converting all the given PowerPoint slideshows into PDF in the desired format and layout (6/page handout).

You can find the final script [here][1].


  [1]: https://github.com/iBug/vbsGadgets/blob/master/AutoConvOffice/AutoConvPPTX.vbs
  [2]: https://www.thespreadsheetguru.com/the-code-vault/powerpoint-vba-save-presentation-as-pdf-in-same-folder
