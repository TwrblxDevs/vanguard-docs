document$.subscribe(function () {
  document.querySelectorAll(".md-content a[href^='http']").forEach(function (link) {
    if (link.hostname !== window.location.hostname) {
      link.rel = "noopener noreferrer";
      link.target = "_blank";
    }
  });
});
