/*
 https://www.smashingmagazine.com/2016/07/improving-user-flow-through-page-transitions/

 You can copy paste this code in your console on smashingmagazine.com
 in order to have cross-fade transition when change page.
 */

var cache = {};
function loadPage(url) {
  if (cache[url]) {
    return new Promise(function(resolve) {
      resolve(cache[url]);
    });
  }

  return fetch(url, {
    method: 'GET'
  }).then(function(response) {
    cache[url] = response.text();
    return cache[url];
  });
}

var main = document.querySelector('body');

function changePage() {
  var url = window.location.href;

  loadPage(url).then(function(responseText) {
    var wrapper = document.createElement('div');
        wrapper.innerHTML = responseText;

    var oldContent = document.querySelector('.initial-content');
    var newContent = wrapper.querySelector('.initial-content');

    main.appendChild(newContent);
    animate(oldContent, newContent);
  });
}

function animate(oldContent, newContent) {
  oldContent.style.position = 'absolute';

  var fadeOut = oldContent.animate({
    opacity: [1, 0]
  }, 333);

  var fadeIn = newContent.animate({
    opacity: [0, 1]
  }, 333);

  fadeIn.onfinish = function() {
    oldContent.parentNode.removeChild(oldContent);
  };
}

window.addEventListener('popstate', changePage);

document.addEventListener('click', function(e) {
  var el = e.target;

  while (el && !el.href) {
    el = el.parentNode;
  }

  if (el) {
    e.preventDefault();
    history.pushState(null, null, el.href);
    changePage();

    return;
  }
});
