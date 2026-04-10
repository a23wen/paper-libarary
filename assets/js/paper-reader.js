(function () {
    function initReadingProgress() {
        const progressBar = document.querySelector(".paper-reading-progress__bar");
        const content = document.querySelector(".paper-single .post-content");

        if (!progressBar || !content) {
            return;
        }

        const updateProgress = () => {
            const rect = content.getBoundingClientRect();
            const contentTop = window.scrollY + rect.top;
            const readableHeight = Math.max(content.offsetHeight - window.innerHeight, 1);
            const progress = Math.min(Math.max((window.scrollY - contentTop) / readableHeight, 0), 1);
            progressBar.style.transform = `scaleX(${progress})`;
        };

        updateProgress();
        window.addEventListener("scroll", updateProgress, { passive: true });
        window.addEventListener("resize", updateProgress);
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", initReadingProgress);
    } else {
        initReadingProgress();
    }
})();
