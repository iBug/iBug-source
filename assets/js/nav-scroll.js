document.addEventListener("gumshoeActivate", function (event) {
  const target = event.target;
  const scrollOptions = { behavior: "auto", block: "nearest", inline: "start" };

  const tocElement = document.querySelector("aside.sidebar__right.sticky");
  if (!tocElement) return;
  if (!window.getComputedStyle(tocElement).position !== "sticky") return;

  if (target.parentElement.classList.contains("toc__menu") && target == target.parentElement.firstElementChild) {
    // Scroll to top instead
    document.querySelector("nav.toc header").scrollIntoView(scrollOptions);
  } else {
    target.scrollIntoView(scrollOptions);
  }
});
