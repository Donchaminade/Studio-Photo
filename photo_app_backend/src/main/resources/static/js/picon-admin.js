(function () {
  var reduced = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  if (!reduced) {
    document.documentElement.classList.add('js-motion');
  }

  function initialsFromName(name) {
    return (name || '')
      .trim()
      .split(/\s+/)
      .filter(Boolean)
      .map(function (part) { return part.charAt(0); })
      .join('')
      .slice(0, 2)
      .toUpperCase();
  }

  function markReveal(el, preset, delay) {
    if (!el || el.dataset.piconReveal) return;
    el.dataset.piconReveal = preset;
    el.classList.add(preset);
    if (delay) {
      el.style.setProperty('--reveal-delay', delay);
    }
  }

  function autoReveal() {
    if (reduced) return;
    var hero = document.querySelector('.welcome-banner, .page-header, body.picon-login .form-section');
    markReveal(hero, 'hero-load', '0s');

    document.querySelectorAll('.content-wrapper > .dashboard-section, .content-wrapper > .row, .filter-section, .dataTables_wrapper').forEach(function (el, i) {
      markReveal(el, 'section-fade-up', Math.min(i, 6) * 0.08 + 's');
    });

    document.querySelectorAll('.stat-card, .action-card').forEach(function (el, i) {
      markReveal(el, i % 2 === 0 ? 'card-slide-up' : 'card-zoom', Math.min(i, 8) * 0.08 + 's');
    });

    document.querySelectorAll('.features-list li, .activity-item').forEach(function (el, i) {
      markReveal(el, 'text-fade', Math.min(i, 8) * 0.06 + 's');
    });

    var nodes = document.querySelectorAll('.hero-load, .section-fade-up, .card-slide-up, .card-zoom, .text-fade');
    if (!('IntersectionObserver' in window)) {
      nodes.forEach(function (el) { el.classList.add('is-in'); });
      return;
    }
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add('is-in');
          io.unobserve(entry.target);
        }
      });
    }, { threshold: 0.15 });
    nodes.forEach(function (el) { io.observe(el); });
  }

  function setupSidebar() {
    var sidebar = document.querySelector('.sidebar');
    var topBar = document.querySelector('.top-bar');
    if (!sidebar || !topBar) return;

    var toggle = document.getElementById('piconSidebarToggle');
    if (!toggle) {
      toggle = document.createElement('button');
      toggle.id = 'piconSidebarToggle';
      toggle.type = 'button';
      toggle.setAttribute('aria-label', 'Ouvrir le menu');
      toggle.innerHTML = '<i class="fas fa-bars"></i>';
      topBar.insertBefore(toggle, topBar.firstChild);
    }

    var backdrop = document.querySelector('.picon-sidebar-backdrop');
    if (!backdrop) {
      backdrop = document.createElement('div');
      backdrop.className = 'picon-sidebar-backdrop';
      document.body.appendChild(backdrop);
    }

    function close() {
      sidebar.classList.remove('picon-open');
      backdrop.classList.remove('is-visible');
    }

    toggle.addEventListener('click', function () {
      sidebar.classList.toggle('picon-open');
      backdrop.classList.toggle('is-visible', sidebar.classList.contains('picon-open'));
    });
    backdrop.addEventListener('click', close);
  }

  function setupInitials() {
    var el = document.getElementById('userInitials');
    if (!el || el.textContent.trim()) return;
    var nameNode = document.querySelector('.user-name');
    if (nameNode) {
      el.textContent = initialsFromName(nameNode.textContent);
    }
  }

  document.addEventListener('DOMContentLoaded', function () {
    autoReveal();
    setupSidebar();
    setupInitials();
  });
})();
