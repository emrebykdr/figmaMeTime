import { db } from "./shared/firebase.js?v=2";
import { mountSidebar, mountTopbar } from "./shared/layout.js?v=2";
import { requireLogin } from "./shared/auth.js?v=2";
import { effectiveStatus } from "./shared/bookingStatus.js?v=2";
import { sendEmail } from "./shared/gmail.js?v=1";
import {
  doc,
  getDoc,
  updateDoc,
  collection,
  query,
  where,
  getDocs,
} from "https://www.gstatic.com/firebasejs/10.13.2/firebase-firestore.js";

requireLogin();

mountSidebar("sidebar-slot", "kullanicilar");
mountTopbar("topbar-slot");

const STATUS_LABELS = {
  waiting: "Bekleyen",
  upcoming: "Onaylı",
  past: "Geçmiş",
  cancelled: "İptal Edildi",
  "no-show": "Gelmedi",
};

const userId = new URLSearchParams(window.location.search).get("id");

const userFormEl = document.getElementById("user-form");
const fullNameEl = document.getElementById("edit-fullname");
const phoneEl = document.getElementById("edit-phone");
const emailEl = document.getElementById("edit-email");
const createdEl = document.getElementById("edit-created");
const formStatusEl = document.getElementById("user-form-status");
const restrictBtnEl = document.getElementById("restrict-btn");
const restrictBadgeEl = document.getElementById("restrict-status-badge");
const blockBtnEl = document.getElementById("block-btn");
const blockBadgeEl = document.getElementById("block-status-badge");
const loginCodeEl = document.getElementById("login-code");
const generateCodeBtnEl = document.getElementById("generate-code-btn");
const loginCodeTimerEl = document.getElementById("login-code-timer");
const upcomingBodyEl = document.getElementById("upcoming-body");
const pastBodyEl = document.getElementById("past-body");

const CODE_LIFETIME_MS = 10 * 60 * 1000;

let currentUser = null;
let codeTimerInterval = null;

function formatDate(timestamp) {
  if (!timestamp?.toDate) return "-";
  return timestamp.toDate().toLocaleDateString("tr-TR");
}

function renderRestrictState() {
  const isRestricted = currentUser.bookingRestricted === true;
  restrictBadgeEl.textContent = isRestricted ? "Randevu Kısıtlı" : "Aktif";
  restrictBadgeEl.className = `status-badge ${isRestricted ? "cancelled" : "upcoming"}`;
  restrictBtnEl.textContent = isRestricted ? "Kısıtlamayı Kaldır" : "Randevuları Kısıtla";
}

function renderBlockState() {
  const isBlocked = currentUser.accountBlocked === true;
  // Hesap engelliyken rozet boş kalmasın diye ayrı bir badge; kısıtlama
  // aktifse zaten görünüyor, engel varsa ikisi birlikte de gösterilebilir.
  blockBadgeEl.textContent = isBlocked ? "Hesap Engelli" : "";
  blockBadgeEl.className = `status-badge ${isBlocked ? "cancelled" : ""}`;
  blockBtnEl.textContent = isBlocked ? "Engeli Kaldır" : "Hesabı Engelle";
}

async function loadUser() {
  if (!userId) {
    formStatusEl.textContent = "Kullanıcı ID'si bulunamadı.";
    userFormEl.hidden = true;
    return;
  }

  const snapshot = await getDoc(doc(db, "users", userId));
  if (!snapshot.exists()) {
    formStatusEl.textContent = "Kullanıcı bulunamadı.";
    userFormEl.hidden = true;
    return;
  }

  currentUser = { id: snapshot.id, ...snapshot.data() };
  fullNameEl.value = currentUser.fullName ?? "";
  phoneEl.value = currentUser.phone ?? "";
  emailEl.value = currentUser.email ?? "-";
  createdEl.value = formatDate(currentUser.createdAt);
  loginCodeEl.value = currentUser.loginCode ?? "Henüz oluşturulmadı";
  renderRestrictState();
  renderBlockState();

  // Sayfa açıldığında, önceden üretilmiş ve süresi henüz dolmamış bir kod
  // varsa geri sayımı kaldığı yerden başlat; süresi dolmuşsa hemen yenile.
  const expiresAt = currentUser.loginCodeExpiresAt;
  if (currentUser.loginCode && typeof expiresAt === "number") {
    if (expiresAt > Date.now()) {
      startCodeTimer(expiresAt);
    } else {
      generateAndSendCode();
    }
  }
}

// Mobil tarafta login_phone_code.dart artık girilen kodu buradaki
// loginCode alanıyla karşılaştırıyor (sabit '12345' yerine).
function generateLoginCode() {
  return String(Math.floor(10000 + Math.random() * 90000));
}

function formatRemaining(ms) {
  const totalSeconds = Math.max(0, Math.ceil(ms / 1000));
  const minutes = String(Math.floor(totalSeconds / 60)).padStart(2, "0");
  const seconds = String(totalSeconds % 60).padStart(2, "0");
  return `${minutes}:${seconds}`;
}

// 10 dakikalık geri sayım; süre dolunca kod otomatik olarak yenilenir ve
// (mümkünse) yeniden email gönderilir. Admin manuel "Kod Oluştur"a bastığında
// da bu sayaç sıfırdan başlatılır.
function startCodeTimer(expiresAt) {
  if (codeTimerInterval) clearInterval(codeTimerInterval);

  const tick = () => {
    const remaining = expiresAt - Date.now();
    if (remaining <= 0) {
      clearInterval(codeTimerInterval);
      codeTimerInterval = null;
      loginCodeTimerEl.textContent = "Yenileniyor...";
      generateAndSendCode();
      return;
    }
    loginCodeTimerEl.textContent = `Yenilenmesine: ${formatRemaining(remaining)}`;
  };

  tick();
  codeTimerInterval = setInterval(tick, 1000);
}

async function generateAndSendCode() {
  if (!currentUser) return;
  const code = generateLoginCode();
  const expiresAt = Date.now() + CODE_LIFETIME_MS;
  generateCodeBtnEl.disabled = true;
  await updateDoc(doc(db, "users", currentUser.id), {
    loginCode: code,
    loginCodeExpiresAt: expiresAt,
  });
  currentUser.loginCode = code;
  currentUser.loginCodeExpiresAt = expiresAt;
  loginCodeEl.value = code;
  startCodeTimer(expiresAt);

  if (!currentUser.email) {
    formStatusEl.textContent = `Kod oluşturuldu (${code}) ama kullanıcının email adresi yok, gönderilemedi.`;
    generateCodeBtnEl.disabled = false;
    return;
  }

  formStatusEl.textContent = `Yeni giriş kodu oluşturuldu: ${code}. Email gönderiliyor (Google izin ekranı açılabilir)...`;
  try {
    await sendEmail(
      currentUser.email,
      "MeTime Giriş Kodunuz",
      `Merhaba ${currentUser.fullName ?? ""},\n\nGiriş kodunuz: ${code}\n\nMeTime`
    );
    formStatusEl.textContent = `Yeni giriş kodu oluşturuldu ve ${currentUser.email} adresine gönderildi: ${code}`;
  } catch (err) {
    console.error(err);
    formStatusEl.textContent = `Kod oluşturuldu (${code}) ama email gönderilemedi: ${err.message}. Kodu manuel iletebilirsin.`;
  }

  generateCodeBtnEl.disabled = false;
}

generateCodeBtnEl.addEventListener("click", () => generateAndSendCode());

restrictBtnEl.addEventListener("click", async () => {
  if (!currentUser) return;
  const newRestricted = !(currentUser.bookingRestricted === true);
  restrictBtnEl.disabled = true;
  await updateDoc(doc(db, "users", currentUser.id), { bookingRestricted: newRestricted });
  currentUser.bookingRestricted = newRestricted;
  renderRestrictState();
  restrictBtnEl.disabled = false;
  formStatusEl.textContent = newRestricted
    ? "Kullanıcının randevu alması kısıtlandı."
    : "Randevu kısıtlaması kaldırıldı.";
});

// Hesabı tamamen engelleme: engellenmiş kullanıcı artık giriş yapamaz
// (bkz. lib/pages/login_phone.dart -> UserService.getUserByPhone kontrolü).
blockBtnEl.addEventListener("click", async () => {
  if (!currentUser) return;
  const newBlocked = !(currentUser.accountBlocked === true);
  blockBtnEl.disabled = true;
  await updateDoc(doc(db, "users", currentUser.id), { accountBlocked: newBlocked });
  currentUser.accountBlocked = newBlocked;
  renderBlockState();
  blockBtnEl.disabled = false;
  formStatusEl.textContent = newBlocked
    ? "Kullanıcının hesabı engellendi, artık giriş yapamaz."
    : "Hesap engeli kaldırıldı.";
});

userFormEl.addEventListener("submit", async (e) => {
  e.preventDefault();
  if (!currentUser) return;

  const fullName = fullNameEl.value.trim();
  const phone = phoneEl.value.trim();
  if (!fullName || !phone) {
    formStatusEl.textContent = "Ad soyad ve telefon boş olamaz.";
    return;
  }

  formStatusEl.textContent = "Kaydediliyor...";
  await updateDoc(doc(db, "users", currentUser.id), { fullName, phone });
  currentUser.fullName = fullName;
  currentUser.phone = phone;
  formStatusEl.textContent = "Kaydedildi.";
});

function renderPastRows(bodyEl, bookings) {
  bodyEl.innerHTML = "";
  if (bookings.length === 0) {
    bodyEl.innerHTML = `<tr><td colspan="7" class="status">Kayıt yok.</td></tr>`;
    return;
  }
  bookings.forEach((booking) => {
    const row = document.createElement("tr");
    const statusLabel = STATUS_LABELS[booking.status] ?? booking.status ?? "";
    row.innerHTML = `
      <td>${booking.salon ?? ""}</td>
      <td>${booking.professional ?? ""}</td>
      <td>${booking.service ?? ""}</td>
      <td>${booking.date ?? ""}</td>
      <td>${booking.time ?? ""}</td>
      <td>${booking.price ?? ""}</td>
      <td><span class="status-badge ${booking.status ?? ""}">${statusLabel}</span></td>
    `;
    bodyEl.appendChild(row);
  });
}

// Gelecek Randevular tablosunda, randevular.js'teki Onay Kuyruğu/Tüm
// Randevular ile aynı işlemler (onayla/iptal et/gelmedi) burada da yapılabilir.
function renderUpcomingRows(bodyEl, bookings) {
  bodyEl.innerHTML = "";
  if (bookings.length === 0) {
    bodyEl.innerHTML = `<tr><td colspan="8" class="status">Kayıt yok.</td></tr>`;
    return;
  }
  bookings.forEach((booking) => {
    const row = document.createElement("tr");
    const displayStatus = effectiveStatus(booking);
    const statusLabel = STATUS_LABELS[displayStatus] ?? displayStatus ?? "";
    const isWaiting = booking.status === "waiting";
    row.innerHTML = `
      <td>${booking.salon ?? ""}</td>
      <td>${booking.professional ?? ""}</td>
      <td>${booking.service ?? ""}</td>
      <td>${booking.date ?? ""}</td>
      <td>${booking.time ?? ""}</td>
      <td>${booking.price ?? ""}</td>
      <td><span class="status-badge ${displayStatus ?? ""}">${statusLabel}</span></td>
      <td class="row-actions">
        ${isWaiting ? '<button class="approve-btn">Onayla</button>' : ""}
        <button class="secondary-btn past-btn">Geçmiş Yap</button>
        <button class="reject-btn cancel-btn">İptal Et</button>
        <button class="reject-btn noshow-btn">Gelmedi</button>
      </td>
    `;

    const approveBtn = row.querySelector(".approve-btn");
    if (approveBtn) {
      approveBtn.addEventListener("click", () => updateBookingStatus(booking.id, "upcoming"));
    }
    row.querySelector(".past-btn").addEventListener("click", () => updateBookingStatus(booking.id, "past"));
    row.querySelector(".cancel-btn").addEventListener("click", () => updateBookingStatus(booking.id, "cancelled"));
    row.querySelector(".noshow-btn").addEventListener("click", () => updateBookingStatus(booking.id, "no-show"));

    bodyEl.appendChild(row);
  });
}

async function updateBookingStatus(bookingId, status) {
  await updateDoc(doc(db, "bookings", bookingId), { status });
  await loadBookingHistory();
}

async function loadBookingHistory() {
  if (!userId) return;

  const snapshot = await getDocs(query(collection(db, "bookings"), where("userId", "==", userId)));
  const bookings = snapshot.docs.map((docSnap) => ({ id: docSnap.id, ...docSnap.data() }));

  const upcoming = bookings
    .filter((b) => b.status === "waiting" || b.status === "upcoming")
    .sort((a, b) => (a.dateIso ?? "").localeCompare(b.dateIso ?? ""));

  const past = bookings
    .filter((b) => b.status === "past" || b.status === "cancelled" || b.status === "no-show")
    .sort((a, b) => (b.dateIso ?? "").localeCompare(a.dateIso ?? ""));

  renderUpcomingRows(upcomingBodyEl, upcoming);
  renderPastRows(pastBodyEl, past);
}

loadUser();
loadBookingHistory();
