$(document).ready(function() {
  const copyText = function(text) {
    const isRTL = document.documentElement.getAttribute('dir') == 'rtl';

    var textarea = document.createElement('textarea');
    // Prevent zooming on iOS
    textarea.style.fontSize = '12pt';
    // Reset box model
    textarea.style.border = '0';
    textarea.style.padding = '0';
    textarea.style.margin = '0';
    // Move element out of screen horizontally
    textarea.style.position = 'absolute';
    textarea.style[isRTL ? 'right' : 'left'] = '-9999px';
    // Move element to the same position vertically
    let yPosition = window.pageYOffset || document.documentElement.scrollTop;
    textarea.style.top = yPosition + "px";

    textarea.setAttribute('readonly', '');
    textarea.value = text;
    document.body.appendChild(textarea);

    let success = true;
    try {
      textarea.select();
      success = document.execCommand("copy");
    } catch {
      success = false;
    }
    textarea.parentNode.removeChild(textarea);
    return success;
  };

  const copyButtonEventListener = function(event) {
    const thisButton = event.target;

    // Locate the <code> element
    let codeBlock = thisButton.nextElementSibling;
    while (codeBlock && codeBlock.tagName.toLowerCase() !== 'code') {
      codeBlock = codeBlock.nextElementSibling;
    }
    if (!codeBlock) {
      // No <code> found - wtf?
      throw new Error("No code block found beside this button.");
    }
    return copyText(codeBlock.innerText);
  };

  document.querySelectorAll(".page__content pre > code").forEach(function(element, index, parentList) {
    // Locate the <pre> element
    const container = element.parentElement;
    // Sanity check - don't add an extra button if there's already one
    if (container.firstElementChild.tagName.toLowerCase() !== 'code') {
      return;
    }
    var copyButton = document.createElement("button");
    copyButton.title = "Copy to clipboard";
    copyButton.className = "copy-button";
    copyButton.innerHTML = '<i class="far fa-copy"></i>';
    copyButton.addEventListener("click", copyButtonEventListener);
    container.prepend(copyButton);
  });
});
