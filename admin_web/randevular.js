import { db } from "./shared/firebase.js";
import { mountSidebar, mountTopbar } from "./shared/layout.js";
import {
  collection,
  query,
  where,
  getDocs,
  doc,
  updateDoc,
  setDoc,
  serverTimestamp,
} from "https://www.gstatic.com/firebasejs/10.13.2/firebase-firestore.js";

mountSidebar("sidebar-slot", "randevular");
mountTopbar("topbar-slot");

// --- Sekme geçişleri (Onay Kuyruğu / Tüm Randevular / Takvim / Yeni Randevu) ---
const tabButtons = document.querySelectorAll(".tab-btn");
const tabPanels = document.querySelectorAll(".tab-panel");

tabButtons.forEach((btn) => {
  btn.addEventListener("click", () => {
    const target = btn.dataset.tab;
    tabButtons.forEach((b) => b.classList.toggle("active", b === btn));
    tabPanels.forEach((panel) => {
      panel.hidden = panel.dataset.panel !== target;
    });
    // Tüm Randevular sekmesi ilk açıldığında veriyi çeker (gereksiz erken sorgu yapılmaz).
    if (target === "all" && !allBookingsLoaded) {
      allBookingsLoaded = true;
      loadAllBookings();
    }
    if (target === "calendar" && !calendarLoaded) {
      calendarLoaded = true;
      loadCalendar();
    }
  });
});

// --- Onay Kuyruğu: status == 'waiting' olan randevuları listele, onayla ---
const statusEl = document.getElementById("status");
const bodyEl = document.getElementById("bookings-body");

async function loadQueue() {
  statusEl.textContent = "Yükleniyor...";
  bodyEl.innerHTML = "";

  const q = query(collection(db, "bookings"), where("status", "==", "waiting"));
  const snapshot = await getDocs(q);

  if (snapshot.empty) {
    statusEl.textContent = "Bekleyen randevu yok.";
    return;
  }

  statusEl.textContent = `${snapshot.size} bekleyen randevu.`;

  snapshot.forEach((docSnap) => {
    const booking = docSnap.data();
    const row = document.createElement("tr");
    row.innerHTML = `
      <td>${booking.salon ?? ""}</td>
      <td>${booking.professional ?? ""}</td>
      <td>${booking.service ?? ""}</td>
      <td>${booking.date ?? ""}</td>
      <td>${booking.time ?? ""}</td>
      <td>${booking.price ?? ""}</td>
      <td class="row-actions">
        <button class="approve-btn">Onayla</button>
        <button class="reject-btn">Reddet</button>
      </td>
    `;

    const approveBtn = row.querySelector(".approve-btn");
    approveBtn.addEventListener("click", () => {
      approveBtn.disabled = true;
      approveBtn.textContent = "Onaylanıyor...";
      updateBookingStatus(docSnap.id, "upcoming");
    });

    const rejectBtn = row.querySelector(".reject-btn");
    rejectBtn.addEventListener("click", () => {
      rejectBtn.disabled = true;
      rejectBtn.textContent = "Reddediliyor...";
      updateBookingStatus(docSnap.id, "cancelled");
    });

    bodyEl.appendChild(row);
  });
}

// Randevu statüsünü değiştiren tüm işlemler (onayla/reddet/iptal/gelmedi)
// buradan geçer; açık olan sekmeler otomatik tazelenir.
async function updateBookingStatus(bookingId, status) {
  await updateDoc(doc(db, "bookings", bookingId), { status });
  await loadQueue();
  if (allBookingsLoaded) await loadAllBookings();
  if (calendarLoaded) await loadCalendar();
}

loadQueue();

// --- Tüm Randevular: statüye göre filtrelenebilen, tarihe göre sıralı liste ---
const allStatusFilterEl = document.getElementById("all-status-filter");
const allStatusEl = document.getElementById("all-status");
const allBodyEl = document.getElementById("all-bookings-body");
let allBookingsLoaded = false;

const STATUS_LABELS = {
  waiting: "Bekleyen",
  upcoming: "Onaylı",
  past: "Geçmiş",
  cancelled: "İptal Edildi",
  "no-show": "Gelmedi",
};

async function loadAllBookings() {
  const statusFilter = allStatusFilterEl.value;
  allStatusEl.textContent = "Yükleniyor...";
  allBodyEl.innerHTML = "";

  const bookingsRef = collection(db, "bookings");
  const q =
    statusFilter === "all"
      ? bookingsRef
      : query(bookingsRef, where("status", "==", statusFilter));
  const snapshot = await getDocs(q);

  if (snapshot.empty) {
    allStatusEl.textContent = "Kayıt yok.";
    return;
  }

  const bookings = snapshot.docs.map((docSnap) => ({ id: docSnap.id, ...docSnap.data() }));
  bookings.sort((a, b) => a.dateIso.localeCompare(b.dateIso));

  allStatusEl.textContent = `${bookings.length} randevu.`;

  bookings.forEach((booking) => {
    const row = document.createElement("tr");
    const statusLabel = STATUS_LABELS[booking.status] ?? booking.status ?? "";
    // Sadece hâlâ aktif (bekleyen/onaylı) randevular iptal/gelmedi olarak işaretlenebilir.
    const isActive = booking.status === "waiting" || booking.status === "upcoming";
    row.innerHTML = `
      <td>${booking.salon ?? ""}</td>
      <td>${booking.professional ?? ""}</td>
      <td>${booking.service ?? ""}</td>
      <td>${booking.date ?? ""}</td>
      <td>${booking.time ?? ""}</td>
      <td>${booking.price ?? ""}</td>
      <td><span class="status-badge ${booking.status ?? ""}">${statusLabel}</span></td>
      <td class="row-actions">
        <button class="secondary-btn edit-btn">Düzenle</button>
        ${isActive ? '<button class="reject-btn cancel-btn">İptal Et</button>' : ""}
        ${isActive ? '<button class="reject-btn noshow-btn">Gelmedi</button>' : ""}
      </td>
    `;

    row.querySelector(".edit-btn").addEventListener("click", () => startEdit(booking));

    const cancelBtn = row.querySelector(".cancel-btn");
    if (cancelBtn) {
      cancelBtn.addEventListener("click", () => updateBookingStatus(booking.id, "cancelled"));
    }

    const noshowBtn = row.querySelector(".noshow-btn");
    if (noshowBtn) {
      noshowBtn.addEventListener("click", () => updateBookingStatus(booking.id, "no-show"));
    }

    allBodyEl.appendChild(row);
  });
}

allStatusFilterEl.addEventListener("change", loadAllBookings);

// --- Takvim: seçilen uzman + tarih için dolu/boş saatler ---
// Not: lib/pages/professionals_calendar.dart'taki uzman/saat listeleriyle
// aynı ("Fark etmez" akışındaki kısa isim tutarsızlığı ayrı bir konu).
const TIME_SLOTS = ["10:00 am", "11:00 am", "01:30 pm", "03:00 pm", "05:00 pm", "07:00 pm"];

const calendarProfessionalEl = document.getElementById("calendar-professional");
const calendarDateEl = document.getElementById("calendar-date");
const calendarStatusEl = document.getElementById("calendar-status");
const calendarSlotsEl = document.getElementById("calendar-slots");
let calendarLoaded = false;

function todayIso() {
  const now = new Date();
  const month = String(now.getMonth() + 1).padStart(2, "0");
  const day = String(now.getDate()).padStart(2, "0");
  return `${now.getFullYear()}-${month}-${day}`;
}

calendarDateEl.value = todayIso();

async function loadCalendar() {
  const professional = calendarProfessionalEl.value;
  const dateIso = calendarDateEl.value;
  if (!dateIso) return;

  calendarStatusEl.textContent = "Yükleniyor...";
  calendarSlotsEl.innerHTML = "";

  // 'waiting' + 'upcoming' birlikte kontrol ediliyor: onay bekleyen bir
  // randevu bile o saati dolu göstermeli (mobildeki getBookedTimes ile aynı mantık).
  const q = query(
    collection(db, "bookings"),
    where("status", "in", ["waiting", "upcoming"]),
    where("professional", "==", professional),
    where("dateIso", "==", dateIso)
  );
  const snapshot = await getDocs(q);
  const bookedTimes = new Set(snapshot.docs.map((docSnap) => docSnap.data().time));

  calendarStatusEl.textContent = `${bookedTimes.size} dolu, ${TIME_SLOTS.length - bookedTimes.size} boş saat.`;

  TIME_SLOTS.forEach((time) => {
    const isBusy = bookedTimes.has(time);
    const pill = document.createElement("div");
    pill.className = `slot-pill ${isBusy ? "busy" : "free"}`;
    pill.innerHTML = `<span>${time}</span><small>${isBusy ? "Dolu" : "Boş"}</small>`;
    calendarSlotsEl.appendChild(pill);
  });
}

calendarProfessionalEl.addEventListener("change", loadCalendar);
calendarDateEl.addEventListener("change", loadCalendar);

// --- Yeni Randevu: manuel oluşturma / düzenleme ---
// lib/pages/professionals_calendar.dart'taki '$dayName, ${gün}' görünüm
// formatıyla aynı, admin panelinde de aynı metin üretiliyor.
const DAY_NAMES = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

function formatDisplayDate(iso) {
  const [year, month, day] = iso.split("-").map(Number);
  const dateObj = new Date(year, month - 1, day);
  return `${DAY_NAMES[dateObj.getDay()]}, ${day}`;
}

const newFormTitleEl = document.getElementById("new-form-title");
const newBookingFormEl = document.getElementById("new-booking-form");
const newUserEl = document.getElementById("new-user");
const newUserSearchEl = document.getElementById("new-user-search");
const newUserOptionsEl = document.getElementById("user-options");
const newProfessionalEl = document.getElementById("new-professional");
const newServiceEl = document.getElementById("new-service");
const newDateEl = document.getElementById("new-date");
const newTimeEl = document.getElementById("new-time");
const newStatusEl = document.getElementById("new-status");
const newSubmitBtnEl = document.getElementById("new-submit-btn");
const newCancelBtnEl = document.getElementById("new-cancel-btn");
const newFormStatusEl = document.getElementById("new-form-status");
let editingBookingId = null;

TIME_SLOTS.forEach((time) => {
  const option = document.createElement("option");
  option.value = time;
  option.textContent = time;
  newTimeEl.appendChild(option);
});

// Kullanıcı seçimi bir arama kutusu (combobox) ile yapılıyor: kullanıcı
// sayısı arttıkça uzun bir dropdown yerine isim/telefonla filtrelenebilen
// bir liste daha kullanışlı. users koleksiyonu bir kere çekilip cache'leniyor.
let allUsers = [];

async function loadUserOptions() {
  const snapshot = await getDocs(collection(db, "users"));
  allUsers = snapshot.docs.map((docSnap) => ({ id: docSnap.id, ...docSnap.data() }));
}

loadUserOptions();

function userLabel(user) {
  return `${user.fullName ?? "İsimsiz"} (${user.phone ?? "-"})`;
}

function selectUser(user) {
  newUserEl.value = user.id;
  newUserSearchEl.value = userLabel(user);
  newUserOptionsEl.hidden = true;
}

function renderUserOptions(filterText) {
  const text = filterText.trim().toLowerCase();
  const matches = text
    ? allUsers.filter(
        (u) =>
          (u.fullName ?? "").toLowerCase().includes(text) ||
          (u.phone ?? "").toLowerCase().includes(text)
      )
    : allUsers;
  const limited = matches.slice(0, 8);

  newUserOptionsEl.innerHTML = "";

  if (limited.length === 0) {
    newUserOptionsEl.innerHTML = `<div class="combobox-empty">Sonuç yok.</div>`;
  } else {
    limited.forEach((user) => {
      const item = document.createElement("div");
      item.className = "combobox-option";
      item.textContent = userLabel(user);
      item.addEventListener("click", () => selectUser(user));
      newUserOptionsEl.appendChild(item);
    });
  }

  newUserOptionsEl.hidden = false;
}

newUserSearchEl.addEventListener("input", () => {
  newUserEl.value = "";
  renderUserOptions(newUserSearchEl.value);
});

newUserSearchEl.addEventListener("focus", () => {
  renderUserOptions(newUserSearchEl.value);
});

document.addEventListener("click", (e) => {
  if (!document.getElementById("user-combobox").contains(e.target)) {
    newUserOptionsEl.hidden = true;
  }
});

function resetNewBookingForm() {
  editingBookingId = null;
  newBookingFormEl.reset();
  newUserOptionsEl.hidden = true;
  newFormTitleEl.textContent = "Yeni Randevu";
  newSubmitBtnEl.textContent = "Randevu Oluştur";
  newCancelBtnEl.hidden = true;
}

function startEdit(booking) {
  editingBookingId = booking.id;
  const user = allUsers.find((u) => u.id === booking.userId);
  newUserEl.value = booking.userId ?? "";
  newUserSearchEl.value = user ? userLabel(user) : "";
  newProfessionalEl.value = booking.professional ?? newProfessionalEl.value;
  newServiceEl.value = booking.service ?? newServiceEl.value;
  newDateEl.value = booking.dateIso;
  newTimeEl.value = booking.time ?? newTimeEl.value;
  newStatusEl.value = booking.status === "waiting" ? "waiting" : "upcoming";
  newFormTitleEl.textContent = "Randevuyu Düzenle";
  newSubmitBtnEl.textContent = "Güncelle";
  newCancelBtnEl.hidden = false;
  newFormStatusEl.textContent = "";

  document.querySelector('.tab-btn[data-tab="new"]').click();
}

newCancelBtnEl.addEventListener("click", () => {
  resetNewBookingForm();
  newFormStatusEl.textContent = "";
});

newBookingFormEl.addEventListener("submit", async (e) => {
  e.preventDefault();

  const userId = newUserEl.value;
  const dateIso = newDateEl.value;
  const time = newTimeEl.value;
  if (!userId) {
    newFormStatusEl.textContent = "Bir kullanıcı seçmelisin.";
    return;
  }
  if (!dateIso || !time) {
    newFormStatusEl.textContent = "Tarih ve saat seçmelisin.";
    return;
  }

  newFormStatusEl.textContent = "Kaydediliyor...";

  const serviceOption = newServiceEl.selectedOptions[0];
  const data = {
    salon: "The Gallery Salon",
    userId,
    professional: newProfessionalEl.value,
    service: serviceOption.value,
    price: serviceOption.dataset.price,
    date: formatDisplayDate(dateIso),
    dateIso,
    time,
    status: newStatusEl.value,
  };

  if (editingBookingId) {
    await updateDoc(doc(db, "bookings", editingBookingId), data);
    newFormStatusEl.textContent = "Randevu güncellendi.";
  } else {
    const docRef = doc(collection(db, "bookings"));
    await setDoc(docRef, {
      ...data,
      bookingId: docRef.id,
      createdAt: serverTimestamp(),
    });
    newFormStatusEl.textContent = "Randevu oluşturuldu.";
  }

  resetNewBookingForm();
  await loadQueue();
  if (allBookingsLoaded) await loadAllBookings();
  if (calendarLoaded) await loadCalendar();
});
