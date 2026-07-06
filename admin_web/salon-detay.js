import { db } from "./shared/firebase.js?v=2";
import { mountSidebar, mountTopbar } from "./shared/layout.js?v=4";
import { requireLogin } from "./shared/auth.js?v=2";
import { effectiveStatus } from "./shared/bookingStatus.js?v=2";
import { notifyBookingStatusChange } from "./shared/notifications.js?v=1";
import {
  doc,
  getDoc,
  updateDoc,
  deleteDoc,
  collection,
  query,
  where,
  getDocs,
} from "https://www.gstatic.com/firebasejs/10.13.2/firebase-firestore.js";

requireLogin();

mountSidebar("sidebar-slot", "salonlar");
mountTopbar("topbar-slot");

const STATUS_LABELS = {
  waiting: "Bekleyen",
  upcoming: "Onaylı",
  past: "Geçmiş",
  cancelled: "İptal Edildi",
  "no-show": "Gelmedi",
};

const salonId = new URLSearchParams(window.location.search).get("id");

const salonFormEl = document.getElementById("salon-form");
const nameEl = document.getElementById("edit-name");
const addressEl = document.getElementById("edit-address");
const phoneEl = document.getElementById("edit-phone");
const emailEl = document.getElementById("edit-email");
const priceTierEl = document.getElementById("edit-price-tier");
const photoUrlEl = document.getElementById("edit-photo-url");
const photoPreviewEl = document.getElementById("photo-preview");
const formStatusEl = document.getElementById("salon-form-status");
const deleteBtnEl = document.getElementById("delete-btn");
const professionalsBodyEl = document.getElementById("professionals-body");
const servicesBodyEl = document.getElementById("services-body");
const upcomingBodyEl = document.getElementById("upcoming-body");
const pastBodyEl = document.getElementById("past-body");

let currentSalon = null;

photoUrlEl.addEventListener("input", () => {
  photoPreviewEl.src = photoUrlEl.value.trim();
});

async function loadSalon() {
  if (!salonId) {
    formStatusEl.textContent = "Şube ID'si bulunamadı.";
    salonFormEl.hidden = true;
    return;
  }

  const snapshot = await getDoc(doc(db, "salons", salonId));
  if (!snapshot.exists()) {
    formStatusEl.textContent = "Şube bulunamadı.";
    salonFormEl.hidden = true;
    return;
  }

  currentSalon = { id: snapshot.id, ...snapshot.data() };
  nameEl.value = currentSalon.name ?? "";
  addressEl.value = currentSalon.address ?? "";
  phoneEl.value = currentSalon.phone ?? "";
  emailEl.value = currentSalon.email ?? "";
  priceTierEl.value = currentSalon.priceTier ?? "";
  photoUrlEl.value = currentSalon.photoUrl ?? "";
  photoPreviewEl.src = currentSalon.photoUrl ?? "";
}

salonFormEl.addEventListener("submit", async (e) => {
  e.preventDefault();
  if (!currentSalon) return;

  const name = nameEl.value.trim();
  if (!name) {
    formStatusEl.textContent = "Salon adı gerekli.";
    return;
  }

  formStatusEl.textContent = "Kaydediliyor...";
  await updateDoc(doc(db, "salons", currentSalon.id), {
    name,
    address: addressEl.value.trim(),
    phone: phoneEl.value.trim(),
    email: emailEl.value.trim(),
    priceTier: priceTierEl.value.trim(),
    photoUrl: photoUrlEl.value.trim(),
  });
  formStatusEl.textContent = "Kaydedildi.";
});

// Bir şube silindiğinde, ona bağlı uzman/hizmet/randevu kayıtları "yetim"
// kalmasın diye önce kontrol edilir; varsa silme engellenir (uzman/hizmet
// admin_web/uzmanlar.html veya hizmetler.html'den başka bir şubeye
// taşınmalı/silinmeli; randevular ise zaten geçmiş kayıtlar olduğu için
// taşınamaz — bu yüzden randevusu olan bir şube hiç silinemez).
deleteBtnEl.addEventListener("click", async () => {
  if (!currentSalon) return;

  const [professionalsSnap, servicesSnap, bookingsSnap] = await Promise.all([
    getDocs(query(collection(db, "professionals"), where("salonId", "==", currentSalon.id))),
    getDocs(query(collection(db, "services"), where("salonId", "==", currentSalon.id))),
    getDocs(query(collection(db, "bookings"), where("salonId", "==", currentSalon.id))),
  ]);
  if (!professionalsSnap.empty || !servicesSnap.empty || !bookingsSnap.empty) {
    window.alert(
      `Bu şubeye bağlı ${professionalsSnap.size} uzman, ${servicesSnap.size} hizmet ve ${bookingsSnap.size} randevu var. Önce uzman/hizmetleri başka bir şubeye taşı veya sil; randevusu olan bir şube silinemez.`
    );
    return;
  }

  const ok = window.confirm(`${currentSalon.name ?? "Bu şubeyi"} silmek istediğine emin misin?`);
  if (!ok) return;

  await deleteDoc(doc(db, "salons", currentSalon.id));
  window.location.href = "salonlar.html";
});

function renderProfessionals(professionals) {
  professionalsBodyEl.innerHTML = "";
  if (professionals.length === 0) {
    professionalsBodyEl.innerHTML = `<tr><td colspan="3" class="status">Bu şubeye bağlı uzman yok.</td></tr>`;
    return;
  }
  professionals.forEach((prof) => {
    const row = document.createElement("tr");
    row.innerHTML = `
      <td>${prof.name ?? ""}</td>
      <td>${prof.role ?? ""}</td>
      <td>${prof.rating ?? ""}</td>
    `;
    professionalsBodyEl.appendChild(row);
  });
}

function renderServices(services) {
  servicesBodyEl.innerHTML = "";
  if (services.length === 0) {
    servicesBodyEl.innerHTML = `<tr><td colspan="4" class="status">Bu şubeye bağlı hizmet yok.</td></tr>`;
    return;
  }
  services.forEach((service) => {
    const row = document.createElement("tr");
    row.innerHTML = `
      <td>${service.name ?? ""}</td>
      <td>${service.category ?? ""}</td>
      <td>${service.duration ?? ""} dk</td>
      <td>${service.price ?? ""}</td>
    `;
    servicesBodyEl.appendChild(row);
  });
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

// admin_web/kullanici-detay.js'teki randevu tablosuyla (onayla/iptal/geçmiş
// yap/gelmedi aksiyonları dahil) birebir aynı davranış, sadece userId yerine
// salonId'ye göre filtrelenmiş bir liste üzerinde çalışıyor.
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
    const isWaiting = booking.status === "waiting";
    row.innerHTML = `
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
  await loadRelatedRecords();
}

async function loadRelatedRecords() {
  if (!salonId) return;

  const [professionalsSnap, servicesSnap, bookingsSnap] = await Promise.all([
    getDocs(query(collection(db, "professionals"), where("salonId", "==", salonId))),
    getDocs(query(collection(db, "services"), where("salonId", "==", salonId))),
    getDocs(query(collection(db, "bookings"), where("salonId", "==", salonId))),
  ]);

  renderProfessionals(professionalsSnap.docs.map((d) => d.data()));
  renderServices(servicesSnap.docs.map((d) => d.data()));

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

loadSalon();
loadRelatedRecords();
