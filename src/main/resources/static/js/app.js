// =============================================
// HOTEL ALTAVISTA — app.js
// =============================================

// Mostrar fecha actual en topbar
(function () {
    const el = document.getElementById('currentDate');
    if (el) {
        const now = new Date();
        const opciones = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' };
        el.textContent = now.toLocaleDateString('es-CR', opciones);
    }
})();

// Toggle sidebar en móvil
(function () {
    const toggle = document.getElementById('sidebarToggle');
    const sidebar = document.querySelector('.sidebar');
    if (toggle && sidebar) {
        toggle.addEventListener('click', () => {
            sidebar.classList.toggle('open');
        });
    }
})();

// Auto-cerrar alertas después de 4 segundos
(function () {
    const alerts = document.querySelectorAll('.alert');
    alerts.forEach(alert => {
        setTimeout(() => {
            alert.style.transition = 'opacity 0.5s';
            alert.style.opacity = '0';
            setTimeout(() => alert.remove(), 500);
        }, 4000);
    });
})();
