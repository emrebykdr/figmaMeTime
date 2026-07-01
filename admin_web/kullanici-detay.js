import { db } from "./shared/firebase.js";
import { mountSidebar, mountTopbar } from "./shared/layout.js";
import {
  doc,
  getDoc,
  updateDoc,
  collection,
  query,
  where,
  getDocs,
} from "https://www.gstatic.com/firebasejs/10.13.2/firebase-firestore.js";

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
const upcomingBodyEl = document.getElementById("upcoming-body");
const pastBodyEl = document.getElementById("past-body");

let currentUser = null;

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

function renderBookingRows(bodyEl, bookings) {
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

  renderBookingRows(upcomingBodyEl, upcoming);
  renderBookingRows(pastBodyEl, past);
}

loadUser();
loadBookingHistory();
