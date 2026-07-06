import { db } from "./shared/firebase.js?v=2";
import { mountSidebar, mountTopbar } from "./shared/layout.js?v=4";
import { requireLogin } from "./shared/auth.js?v=2";
import { effectiveStatus } from "./shared/bookingStatus.js?v=2";
import { notifyBookingStatusChange } from "./shared/notifications.js?v=1";
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
const verifyBadgeEl = document.getElementById("verify-status-badge");
const restrictBtnEl = document.getElementById("restrict-btn");
const restrictBadgeEl = document.getElementById("restrict-status-badge");
const blockBtnEl = document.getElementById("block-btn");
const blockBadgeEl = document.getElementById("block-status-badge");
const upcomingBodyEl = document.getElementById("upcoming-body");
const pastBodyEl = document.getElementById("past-body");

let currentUser = null;

function formatDate(timestamp) {
  if (!timestamp?.toDate) return "-";
  return timestamp.toDate().toLocaleDateString("tr-TR");
}

// Kullanıcı mobil tarafta (Hesap Ayarları -> "Verify this email") email'ini
// doğruladıysa bunu buradan da görebilmek için (bkz. UserService.
// confirmEmailVerification -> users/{id}.emailVerified).
function renderVerifyState() {
  const isVerified = currentUser.emailVerified === true;
  verifyBadgeEl.textContent = isVerified ? "Email Doğrulanmış" : "Email Doğrulanmamış";
  verifyBadgeEl.className = `status-badge ${isVerified ? "upcoming" : "past"}`;
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
  renderVerifyState();
  renderRestrictState();
  renderBlockState();
}

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
  await notifyBookingStatusChange(db, bookingId, status);
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
