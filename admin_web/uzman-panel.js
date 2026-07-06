import { db } from "./shared/firebase.js?v=2";
import { requireProfessionalLogin, professionalLogout } from "./shared/auth.js?v=4";
import { effectiveStatus } from "./shared/bookingStatus.js?v=2";
import { notifyBookingStatusChange } from "./shared/notifications.js?v=1";
import {
  doc,
  updateDoc,
  collection,
  query,
  where,
  getDocs,
  addDoc,
  serverTimestamp,
} from "https://www.gstatic.com/firebasejs/10.13.2/firebase-firestore.js";

const professional = requireProfessionalLogin();
if (professional) {
  document.getElementById("professional-name").textContent = professional.name ?? "";
}

document.getElementById("logout-btn").addEventListener("click", () => {
  professionalLogout();
});

// --- Sekme geçişleri (Randevularım / İzin Talebi) — admin_web/randevular.js
// ile aynı desen. ---
const tabButtons = document.querySelectorAll(".tab-btn");
const tabPanels = document.querySelectorAll(".tab-panel");

tabButtons.forEach((btn) => {
  btn.addEventListener("click", () => {
    const target = btn.dataset.tab;
    tabButtons.forEach((b) => b.classList.toggle("active", b === btn));
    tabPanels.forEach((panel) => {
      panel.hidden = panel.dataset.panel !== target;
    });
  });
});

const STATUS_LABELS = {
  waiting: "Bekleyen",
  upcoming: "Onaylı",
  past: "Geçmiş",
  cancelled: "İptal Edildi",
  "no-show": "Gelmedi",
};

const upcomingBodyEl = document.getElementById("upcoming-body");
const pastBodyEl = document.getElementById("past-body");

let allUsers = [];

function customerLabel(userId) {
  const user = allUsers.find((u) => u.id === userId);
  return user?.fullName ?? "Bilinmeyen müşteri";
}

function renderPastRows(bodyEl, bookings) {
  bodyEl.innerHTML = "";
  if (bookings.length === 0) {
    bodyEl.innerHTML = `<tr><td colspan="6" class="status">Kayıt yok.</td></tr>`;
    return;
  }
  bookings.forEach((booking) => {
    const row = document.createElement("tr");
    const statusLabel = STATUS_LABELS[booking.status] ?? booking.status ?? "";
    row.innerHTML = `
      <td>${customerLabel(booking.userId)}</td>
      <td>${booking.service ?? ""}</td>
      <td>${booking.date ?? ""}</td>
      <td>${booking.time ?? ""}</td>
      <td>${booking.price ?? ""}</td>
      <td><span class="status-badge ${booking.status ?? ""}">${statusLabel}</span></td>
    `;
    bodyEl.appendChild(row);
  });
}

// Uzman sadece kendi randevusunu "Geçmiş Yap" veya "İptal Et" olarak
// işaretleyebilir; onaylama/gelmedi gibi diğer aksiyonlar admin'e özel kalır
// (bkz. admin_web/kullanici-detay.js'teki tam aksiyon seti).
function renderUpcomingRows(bodyEl, bookings) {
  bodyEl.innerHTML = "";
  if (bookings.length === 0) {
    bodyEl.innerHTML = `<tr><td colspan="7" class="status">Kayıt yok.</td></tr>`;
    return;
  }
  bookings.forEach((booking) => {
    const row = document.createElement("tr");
    const displayStatus = effectiveStatus(booking);
    const statusLabel = STATUS_LABELS[displayStatus] ?? displayStatus ?? "";
    row.innerHTML = `
      <td>${customerLabel(booking.userId)}</td>
      <td>${booking.service ?? ""}</td>
      <td>${booking.date ?? ""}</td>
      <td>${booking.time ?? ""}</td>
      <td>${booking.price ?? ""}</td>
      <td><span class="status-badge ${displayStatus ?? ""}">${statusLabel}</span></td>
      <td class="row-actions">
        <button class="secondary-btn past-btn">Geçmiş Yap</button>
        <button class="reject-btn cancel-btn">İptal Et</button>
      </td>
    `;

    row.querySelector(".past-btn").addEventListener("click", () => updateBookingStatus(booking.id, "past"));
    row.querySelector(".cancel-btn").addEventListener("click", () => updateBookingStatus(booking.id, "cancelled"));

    bodyEl.appendChild(row);
  });
}

async function updateBookingStatus(bookingId, status) {
  await updateDoc(doc(db, "bookings", bookingId), { status });
  await notifyBookingStatusChange(db, bookingId, status);
  await loadBookings();
}

async function loadBookings() {
  if (!professional) return;

  const usersSnap = await getDocs(collection(db, "users"));
  allUsers = usersSnap.docs.map((docSnap) => ({ id: docSnap.id, ...docSnap.data() }));

  // salonId filtresi, aynı isimli bir uzman başka bir şubede olsa bile
  // randevuların karışmamasını sağlar (bkz. randevular.js'teki Takvim
  // sekmesinde yapılan aynı düzeltme).
  const bookingsSnap = await getDocs(
    query(
      collection(db, "bookings"),
      where("professional", "==", professional.name),
      where("salonId", "==", professional.salonId)
    )
  );
  const bookings = bookingsSnap.docs.map((docSnap) => ({ id: docSnap.id, ...docSnap.data() }));

  const upcoming = bookings
    .filter((b) => b.status === "waiting" || b.status === "upcoming")
    .sort((a, b) => (a.dateIso ?? "").localeCompare(b.dateIso ?? ""));

  const past = bookings
    .filter((b) => b.status === "past" || b.status === "cancelled" || b.status === "no-show")
    .sort((a, b) => (b.dateIso ?? "").localeCompare(a.dateIso ?? ""));

  renderUpcomingRows(upcomingBodyEl, upcoming);
  renderPastRows(pastBodyEl, past);
}

// --- İzin Talebi: admin_web/uzmanlar.html'deki "İzin Talepleri" bölümünde
// onaylanana kadar 'pending' statüsünde bekler. Onaylanınca
// professionals/{id}.daysOff'a eklenir (bkz. uzmanlar.js ->
// approveLeaveRequest); reddedilirse hiçbir şey değişmez. Uzman burada
// sadece kendi taleplerini görüp yeni talep gönderebilir, onaylayamaz.
const LEAVE_STATUS_LABELS = {
  pending: "Bekliyor",
  approved: "Onaylandı",
  rejected: "Reddedildi",
};
const LEAVE_STATUS_BADGE_CLASS = {
  pending: "waiting",
  approved: "upcoming",
  rejected: "cancelled",
};

const leaveFormEl = document.getElementById("leave-form");
const leaveDateEl = document.getElementById("leave-date");
const leaveReasonEl = document.getElementById("leave-reason");
const leaveFormStatusEl = document.getElementById("leave-form-status");
const leaveRequestsBodyEl = document.getElementById("leave-requests-body");

function renderLeaveRequests(requests) {
  leaveRequestsBodyEl.innerHTML = "";
  if (requests.length === 0) {
    leaveRequestsBodyEl.innerHTML = `<tr><td colspan="3" class="status">Henüz izin talebin yok.</td></tr>`;
    return;
  }
  requests.forEach((request) => {
    const row = document.createElement("tr");
    const badgeClass = LEAVE_STATUS_BADGE_CLASS[request.status] ?? "";
    const label = LEAVE_STATUS_LABELS[request.status] ?? request.status ?? "";
    row.innerHTML = `
      <td>${request.date ?? ""}</td>
      <td>${request.reason ?? ""}</td>
      <td><span class="status-badge ${badgeClass}">${label}</span></td>
    `;
    leaveRequestsBodyEl.appendChild(row);
  });
}

async function loadLeaveRequests() {
  if (!professional) return;
  const snapshot = await getDocs(
    query(collection(db, "leaveRequests"), where("professionalId", "==", professional.id))
  );
  const requests = snapshot.docs
    .map((docSnap) => ({ id: docSnap.id, ...docSnap.data() }))
    .sort((a, b) => (b.date ?? "").localeCompare(a.date ?? ""));
  renderLeaveRequests(requests);
}

leaveFormEl.addEventListener("submit", async (e) => {
  e.preventDefault();
  if (!professional) return;

  const date = leaveDateEl.value;
  if (!date) {
    leaveFormStatusEl.textContent = "Bir tarih seçmelisin.";
    return;
  }

  leaveFormStatusEl.textContent = "Gönderiliyor...";
  await addDoc(collection(db, "leaveRequests"), {
    professionalId: professional.id,
    professionalName: professional.name,
    salonId: professional.salonId,
    date,
    reason: leaveReasonEl.value.trim(),
    status: "pending",
    createdAt: serverTimestamp(),
  });

  leaveFormStatusEl.textContent = "Talep gönderildi.";
  leaveFormEl.reset();
  await loadLeaveRequests();
});

loadBookings();
loadLeaveRequests();
