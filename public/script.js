// Initialize AOS (Animate On Scroll)
AOS.init({
  duration: 1000,
  easing: "ease-in-out",
  once: true,
});

// Smooth Scroll for Anchors
document.querySelectorAll('a[href^="#"]').forEach((anchor) => {
  anchor.addEventListener("click", function (e) {
    e.preventDefault();

    document.querySelector(this.getAttribute("href")).scrollIntoView({
      behavior: "smooth",
      block: "start",
    });
  });
});
