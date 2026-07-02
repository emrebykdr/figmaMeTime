// Tüm admin sayfalarında aynı sol menü (sidebar) ve üst bar (topbar)
// tekrar tekrar yazılmasın diye buradan enjekte ediliyor.
// Kullanım: her sayfada <div id="sidebar-slot"></div> ve
// <div id="topbar-slot"></div> bırakılır, sayfa sonunda
// mountSidebar('sidebar-slot', 'randevular') gibi çağrılır.
import { logout } from "./auth.js";

const NAV_ITEMS = [
  { key: "dashboard", href: "index.html", label: "Dashboard" },
  { key: "randevular", href: "randevular.html", label: "Randevular" },
  { key: "kullanicilar", href: "kullanicilar.html", label: "Kullanıcılar" },
  { key: "uzmanlar", href: "uzmanlar.html", label: "Uzmanlar" },
  { key: "hizmetler", href: "hizmetler.html", label: "Hizmetler" },
  { key: "salon", href: "#", label: "Salon Bilgileri" },
];

export function mountSidebar(containerId, activeKey) {
  const navHtml = NAV_ITEMS.map(
    (item) => `
      <a class="nav-item${item.key === activeKey ? " active" : ""}" href="${item.href}">
        ${item.label}
      </a>`
  ).join("");

  const html = `
    <aside class="sidebar">
      <div class="brand">MeTime Admin</div>
      <nav class="nav">${navHtml}</nav>
      <div class="sidebar-footer">
        <a class="nav-item" href="#">Yardım</a>
        <a class="nav-item" href="#" id="logout-link"><span class="nav-icon">↩</span> Çıkış</a>
      </div>
    </aside>`;

  document.getElementById(containerId).outerHTML = html;
  document.getElementById("logout-link").addEventListener("click", (e) => {
    e.preventDefault();
    logout();
  });
}

export function mountTopbar(containerId) {
  const html = `
    <header class="topbar">
      <input class="search" type="text" placeholder="Ara..." />
      <div class="topbar-actions">
        <span class="icon-btn">🔔</span>
        <span class="avatar">A</span>
      </div>
    </header>`;

  document.getElementById(containerId).outerHTML = html;
}
