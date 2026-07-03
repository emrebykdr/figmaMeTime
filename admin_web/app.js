import { db } from "./shared/firebase.js?v=2";
import { mountSidebar, mountTopbar } from "./shared/layout.js?v=2";
import { requireLogin } from "./shared/auth.js?v=2";
import { generateMasterCode, formatRemaining } from "./shared/loginCode.js?v=3";
import { collection, getDocs } from "https://www.gstatic.com/firebasejs/10.13.2/firebase-firestore.js";

const loggedIn = requireLogin();
if (loggedIn) {
  mountSidebar("sidebar-slot", "dashboard");
  mountTopbar("topbar-slot");
}

// Bir randevu "aktif" sayılır (doluluk/adet hesaplarına dahil edilir) ama
// gerçekleşmiş/onaylanmış olmayabilir. Ciro sadece onaylanmış+gerçekleşmiş
// (upcoming/past) randevulardan hesaplanıyor; cancelled/no-show hariç.
const ACTIVE_STATUSES = ["waiting", "upcoming", "past"];
const REVENUE_STATUSES = ["upcoming", "past"];

// admin_web/uzmanlar.js'teki DAY_ORDER ile aynı anahtarlar, JS Date.getDay()
// (0=Pazar) sırasına göre eşleniyor.
const JS_DAY_TO_KEY = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"];

function isoDate(date) {
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${date.getFullYear()}-${month}-${day}`;
}

function startOfWeek(date) {
  const d = new Date(date);
  const day = d.getDay();
  const diff = day === 0 ? -6 : 1 - day; // Pazartesi haftanın başlangıcı
  d.setDate(d.getDate() + diff);
  return d;
}

function endOfWeek(date) {
  const start = startOfWeek(date);
  const end = new Date(start);
  end.setDate(start.getDate() + 6);
  return end;
}

function startOfMonth(date) {
  return new Date(date.getFullYear(), date.getMonth(), 1);
}

function endOfMonth(date) {
  return new Date(date.getFullYear(), date.getMonth() + 1, 0);
}

function parsePrice(priceStr) {
  const num = parseFloat((priceStr ?? "").replace(/[^0-9.]/g, ""));
  return Number.isNaN(num) ? 0 : num;
}

function formatMoney(amount) {
  return `$${amount.toFixed(0)}`;
}

// Bir tarih aralığında, uzmanların çalışma saatlerine/izin günlerine göre
// toplam kaç randevu slotu açılabileceğini (kapasite) hesaplar.
function calculateCapacity(professionals, startDate, endDate) {
  let capacity = 0;
  const cursor = new Date(startDate);
  cursor.setHours(0, 0, 0, 0);
  const last = new Date(endDate);
  last.setHours(0, 0, 0, 0);

  while (cursor <= last) {
    const dayKey = JS_DAY_TO_KEY[cursor.getDay()];
    const iso = isoDate(cursor);
    professionals.forEach((prof) => {
      const daysOff = prof.daysOff ?? [];
      if (daysOff.includes(iso)) return;
      const slots = prof.workingHours?.[dayKey] ?? [];
      capacity += slots.length;
    });
    cursor.setDate(cursor.getDate() + 1);
  }

  return capacity;
}

function periodStats(bookings, professionals, startDate, endDate) {
  const startIso = isoDate(startDate);
  const endIso = isoDate(endDate);

  const periodBookings = bookings.filter(
    (b) => b.dateIso && b.dateIso >= startIso && b.dateIso <= endIso
  );
  const activeBookings = periodBookings.filter((b) => ACTIVE_STATUSES.includes(b.status));
  const revenue = periodBookings
    .filter((b) => REVENUE_STATUSES.includes(b.status))
    .reduce((sum, b) => sum + parsePrice(b.price), 0);

  const capacity = calculateCapacity(professionals, startDate, endDate);
  const occupancy = capacity > 0 ? Math.round((activeBookings.length / capacity) * 100) : 0;

  return { count: activeBookings.length, occupancy, revenue };
}

function renderPeriod(prefix, stats) {
  document.getElementById(`${prefix}-count`).textContent = stats.count;
  document.getElementById(`${prefix}-occupancy`).textContent = stats.occupancy;
  document.getElementById(`${prefix}-revenue`).textContent = formatMoney(stats.revenue);
}

function topCounts(bookings, field, limit = 3) {
  const counts = {};
  bookings.forEach((b) => {
    const key = b[field];
    if (!key) return;
    counts[key] = (counts[key] ?? 0) + 1;
  });
  return Object.entries(counts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, limit);
}

function renderTopList(elementId, entries, emptyText) {
  const el = document.getElementById(elementId);
  el.innerHTML = "";

  if (entries.length === 0) {
    el.innerHTML = `<li class="top-list-empty">${emptyText}</li>`;
    return;
  }

  entries.forEach(([name, count], index) => {
    const li = document.createElement("li");
    li.innerHTML = `
      <span><span class="rank">${index + 1}.</span>${name}</span>
      <span class="count-pill">${count} randevu</span>
    `;
    el.appendChild(li);
  });
}

async function loadDashboard() {
  const [bookingsSnap, professionalsSnap, usersSnap] = await Promise.all([
    getDocs(collection(db, "bookings")),
    getDocs(collection(db, "professionals")),
    getDocs(collection(db, "users")),
  ]);

  const bookings = bookingsSnap.docs.map((d) => d.data());
  const professionals = professionalsSnap.docs.map((d) => d.data());

  // --- Bekleyen onay uyarısı (badge) ---
  const pendingCount = bookings.filter((b) => b.status === "waiting").length;
  const alertEl = document.getElementById("pending-alert");
  const alertTextEl = document.getElementById("pending-alert-text");
  if (pendingCount > 0) {
    alertEl.classList.add("warning");
    alertTextEl.textContent = `${pendingCount} randevu onay bekliyor.`;
  } else {
    alertEl.classList.remove("warning");
    alertTextEl.textContent = "Onay bekleyen randevu yok.";
  }

  // --- Günlük / haftalık / aylık randevu özeti ---
  const today = new Date();
  renderPeriod("today", periodStats(bookings, professionals, today, today));
  renderPeriod("week", periodStats(bookings, professionals, startOfWeek(today), endOfWeek(today)));
  renderPeriod("month", periodStats(bookings, professionals, startOfMonth(today), endOfMonth(today)));

  // --- En çok tercih edilen hizmet/uzman ---
  renderTopList("top-services", topCounts(bookings, "service"), "Henüz randevu yok.");
  renderTopList("top-professionals", topCounts(bookings, "professional"), "Henüz randevu yok.");

  // --- Genel sayılar ---
  document.getElementById("stat-users").textContent = usersSnap.size;
  document.getElementById("stat-total-bookings").textContent = bookings.length;
  document.getElementById("stat-professionals").textContent = professionals.length;
}

// --- Master Giriş Kodu: kullanıcı seçmeden, herhangi bir hesap için geçerli
// TEK bir kod üretir (bkz. shared/loginCode.js -> generateMasterCode ve
// UserService.watchMasterCode). Belirli bir kullanıcıya bağlı olmadığı için
// email gönderilmez, kod sadece burada gösterilir.
const loginCodeGenerateBtnEl = document.getElementById("login-code-generate-btn");
const loginCodeResultRowEl = document.getElementById("login-code-result-row");
const loginCodeResultEl = document.getElementById("login-code-result");
const loginCodeTimerEl = document.getElementById("login-code-timer");
const loginCodeStatusEl = document.getElementById("login-code-status");

let loginCodeTimerInterval = null;

function startLoginCodeTimer(expiresAt) {
  if (loginCodeTimerInterval) clearInterval(loginCodeTimerInterval);

  const tick = () => {
    const remaining = expiresAt - Date.now();
    if (remaining <= 0) {
      clearInterval(loginCodeTimerInterval);
      loginCodeTimerInterval = null;
      loginCodeTimerEl.textContent = "Süresi doldu";
      return;
    }
    loginCodeTimerEl.textContent = `Geçerlilik: ${formatRemaining(remaining)}`;
  };

  tick();
  loginCodeTimerInterval = setInterval(tick, 1000);
}

loginCodeGenerateBtnEl.addEventListener("click", async () => {
  loginCodeGenerateBtnEl.disabled = true;
  loginCodeStatusEl.textContent = "Kod oluşturuluyor...";

  const result = await generateMasterCode(db);
  loginCodeResultRowEl.hidden = false;
  loginCodeResultEl.value = result.code;
  startLoginCodeTimer(result.expiresAt);
  loginCodeStatusEl.textContent = `Master kod oluşturuldu: ${result.code}. Herhangi bir hesabın giriş kodu ekranında kullanılabilir.`;

  loginCodeGenerateBtnEl.disabled = false;
});

if (loggedIn) {
  loadDashboard();
}
