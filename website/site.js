// The light/dark switch, the scripts on the tablet, and the recitation demo.
(function () {
  var root = document.documentElement;
  var dark = window.matchMedia("(prefers-color-scheme: dark)");

  // ---- Theme: follows the device until the visitor chooses. ----
  function isDark() {
    var chosen = root.dataset.theme;
    return chosen ? chosen === "dark" : dark.matches;
  }

  function update() {
    var d = isDark();
    document.querySelectorAll(".theme-toggle").forEach(function (b) {
      b.setAttribute("aria-label", d ? "Switch to light mode" : "Switch to dark mode");
    });
    var meta = document.querySelector('meta[name="theme-color"]');
    if (meta) meta.setAttribute("content", d ? "#151614" : "#f4f0e8");
  }

  document.querySelectorAll(".theme-toggle").forEach(function (b) {
    b.addEventListener("click", function () {
      var next = isDark() ? "light" : "dark";
      root.dataset.theme = next;
      try {
        localStorage.setItem("theme", next);
      } catch (e) {}
      update();
    });
  });
  if (dark.addEventListener) dark.addEventListener("change", update);
  update();

  // ---- Recitation demo: when the player's line fills, on to the next
  // ayah, then back to the first. ----
  var demo = document.querySelector(".listen-demo");
  if (demo) {
    var bar = demo.querySelector(".player-progress");
    var label = demo.querySelector(".player-ayah");
    // The second ayah's pictures are hidden until needed: load them now.
    demo.querySelectorAll(".ayah-3").forEach(function (img) {
      new Image().src = img.getAttribute("src");
    });
    bar.addEventListener("animationiteration", function () {
      var next = demo.dataset.ayah === "2" ? "3" : "2";
      demo.dataset.ayah = next;
      label.textContent = "Al-Mulk 67:" + next;
    });
  }

  // ---- Scripts: choose one to see it on the tablet. Until the visitor
  // chooses, they take turns while the tablet is in view. ----
  var tabs = Array.prototype.slice.call(document.querySelectorAll("[data-layout]"));
  var shots = Array.prototype.slice.call(document.querySelectorAll(".layout-shot"));
  var panel = document.querySelector(".tablet");
  if (!tabs.length || !shots.length || !panel) return;
  var still = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  var current = 0;
  var timer = null;

  function srcFor(layout, shot) {
    return "img/layout-" + layout + shot.dataset.variant + ".webp";
  }

  // Load every page ahead, in both themes, so switching is instant.
  tabs.forEach(function (t) {
    shots.forEach(function (shot) { new Image().src = srcFor(t.dataset.layout, shot); });
  });

  function show(i, focus) {
    current = (i + tabs.length) % tabs.length;
    tabs.forEach(function (t, j) {
      t.setAttribute("aria-selected", j === current ? "true" : "false");
      t.tabIndex = j === current ? 0 : -1;
    });
    var t = tabs[current];
    if (focus) t.focus();
    var alt = "The opening of Surah Al-Fath in the " + t.dataset.name + " script.";
    function swap() {
      shots.forEach(function (shot) {
        shot.src = srcFor(t.dataset.layout, shot);
        shot.alt = alt;
      });
    }
    if (still) return swap();
    shots.forEach(function (shot) { shot.classList.add("fading"); });
    setTimeout(function () {
      swap();
      shots.forEach(function (shot) { shot.classList.remove("fading"); });
    }, 250);
  }

  function stop() {
    clearInterval(timer);
    timer = null;
  }

  tabs.forEach(function (t, i) {
    t.tabIndex = i === 0 ? 0 : -1;
    t.addEventListener("click", function () {
      stop();
      show(i);
    });
    // Arrow keys move between layouts, as in any tab list.
    t.addEventListener("keydown", function (e) {
      var step = { ArrowDown: 1, ArrowRight: 1, ArrowUp: -1, ArrowLeft: -1 }[e.key];
      if (!step) return;
      e.preventDefault();
      stop();
      show(current + step, true);
    });
  });

  if (still || !("IntersectionObserver" in window)) return;
  var chosen = false;
  tabs.forEach(function (t) {
    t.addEventListener("click", function () { chosen = true; });
    t.addEventListener("keydown", function () { chosen = true; });
  });
  new IntersectionObserver(
    function (entries) {
      var seen = entries.some(function (e) { return e.isIntersecting; });
      if (seen && !timer && !chosen) {
        timer = setInterval(function () { show(current + 1); }, 3200);
      } else if (!seen) {
        stop();
      }
    },
    { threshold: 0.5 }
  ).observe(panel);
})();
