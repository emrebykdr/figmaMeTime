import { db } from "./shared/firebase.js?v=2";
import { mountSidebar, mountTopbar } from "./shared/layout.js?v=5";
import { requireLogin } from "./shared/auth.js?v=4";
import { PAGE_SIZE, renderPagination } from "./shared/pagination.js?v=2";
import { effectiveStatus } from "./shared/bookingStatus.js?v=2";
import { notifyBookingStatusChange } from "./shared/notifications.js?v=1";
import { attachCombobox } from "./shared/combobox.js?v=2";
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

requireLogin();

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

// Kullanıcı adları (Onay Kuyruğu, Tüm Randevular ve Yeni Randevu'daki arama
// kutusu için) users koleksiyonundan bir kere çekilip cache'leniyor.
// Onay Kuyruğu ilk render'ından önce yüklenmesi gerektiği için burada,
// dosyanın başında tanımlanıyor (bkz. dosya sonundaki loadUserOptions().then(loadQueue)).
let allUsers = [];

async function loadUserOptions() {
  const snapshot = await getDocs(collection(db, "users"));
  allUsers = snapshot.docs.map((docSnap) => ({ id: docSnap.id, ...docSnap.data() }));
}

function userLabel(user) {
  return `${user.fullName ?? "İsimsiz"} (${user.phone ?? "-"})`;
}

function customerLabel(userId) {
  const user = allUsers.find((u) => u.id === userId);
  if (user) return user.fullName ?? "İsimsiz";
  return userId ? "Bilinmeyen kullanıcı" : "-";
}

// --- Onay Kuyruğu: status == 'waiting' olan randevuları listele, onayla ---
const statusEl = document.getElementById("status");
const bodyEl = document.getElementById("bookings-body");
const queuePaginationEl = document.getElementById("queue-pagination");
let queueBookings = [];
let queuePage = 1;

async function loadQueue() {
  statusEl.textContent = "Yükleniyor...";

  const q = query(collection(db, "bookings"), where("status", "==", "waiting"));
  const snapshot = await getDocs(q);
  queueBookings = snapshot.docs.map((docSnap) => ({ id: docSnap.id, ...docSnap.data() }));
  queuePage = 1;
  renderQueuePage();
}

function renderQueuePage() {
  bodyEl.innerHTML = "";

  if (queueBookings.length === 0) {
    statusEl.textContent = "Bekleyen randevu yok.";
    queuePaginationEl.innerHTML = "";
    return;
  }

  statusEl.textContent = `${queueBookings.length} bekleyen randevu.`;

  const start = (queuePage - 1) * PAGE_SIZE;
  queueBookings.slice(start, start + PAGE_SIZE).forEach((booking) => {
    const row = document.createElement("tr");
    row.innerHTML = `
      <td>${customerLabel(booking.userId)}</td>
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
      updateBookingStatus(booking.id, "upcoming");
    });

    const rejectBtn = row.querySelector(".reject-btn");
    rejectBtn.addEventListener("click", () => {
      rejectBtn.disabled = true;
      rejectBtn.textContent = "Reddediliyor...";
      updateBookingStatus(booking.id, "cancelled");
    });

    bodyEl.appendChild(row);
  });

  renderPagination(queuePaginationEl, queuePage, queueBookings.length, PAGE_SIZE, (newPage) => {
    queuePage = newPage;
    renderQueuePage();
  });
}

// Randevu statüsünü değiştiren tüm işlemler (onayla/reddet/iptal/gelmedi)
// buradan geçer; açık olan sekmeler otomatik tazelenir.
async function updateBookingStatus(bookingId, status) {
  await updateDoc(doc(db, "bookings", bookingId), { status });
  await notifyBookingStatusChange(db, bookingId, status);
  await loadQueue();
  if (allBookingsLoaded) await loadAllBookings();
  if (calendarLoaded) await loadCalendar();
}

// Kullanıcı listesi yüklenmeden kuyruk render edilirse müşteri isimleri
// boş görünür; bu yüzden ilk render'dan önce sırayla bekleniyor.
loadUserOptions().then(loadQueue);

// --- Tüm Randevular: statüye göre filtrelenebilen, tarihe göre sıralı liste ---
const allStatusFilterEl = document.getElementById("all-status-filter");
const allStatusEl = document.getElementById("all-status");
const allBodyEl = document.getElementById("all-bookings-body");
const allPaginationEl = document.getElementById("all-pagination");
let allBookingsLoaded = false;
let allBookingsData = [];
let allPage = 1;

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

  // 'past' statüsü Firestore'da gerçekten set edilmiyor (bkz. shared/bookingStatus.js),
  // bu yüzden filtreyi Firestore'a değil, tüm kayıtları çekip client'ta
  // effectiveStatus()'a göre uyguluyoruz.
  const snapshot = await getDocs(collection(db, "bookings"));
  const allBookings = snapshot.docs.map((docSnap) => ({ id: docSnap.id, ...docSnap.data() }));

  allBookingsData =
    statusFilter === "all"
      ? allBookings
      : allBookings.filter((b) => effectiveStatus(b) === statusFilter);

  allBookingsData.sort((a, b) => a.dateIso.localeCompare(b.dateIso));
  allPage = 1;
  renderAllBookingsPage();
}

function renderAllBookingsPage() {
  allBodyEl.innerHTML = "";

  if (allBookingsData.length === 0) {
    allStatusEl.textContent = "Kayıt yok.";
    allPaginationEl.innerHTML = "";
    return;
  }

  allStatusEl.textContent = `${allBookingsData.length} randevu.`;

  const start = (allPage - 1) * PAGE_SIZE;
  allBookingsData.slice(start, start + PAGE_SIZE).forEach((booking) => {
    const row = document.createElement("tr");
    const displayStatus = effectiveStatus(booking);
    const statusLabel = STATUS_LABELS[displayStatus] ?? displayStatus ?? "";
    // Rozet, tarihi geçmiş randevularda 'Geçmiş' gösterir ama işlemler gerçek
    // statüye (waiting/upcoming) göre çalışmaya devam eder — admin, tarihi
    // geçmiş ama hâlâ kapatılmamış bir randevuyu iptal/gelmedi olarak işaretleyebilir.
    const isActive = booking.status === "waiting" || booking.status === "upcoming";
    row.innerHTML = `
      <td>${booking.salon ?? ""}</td>
      <td>${booking.professional ?? ""}</td>
      <td>${booking.service ?? ""}</td>
      <td>${booking.date ?? ""}</td>
      <td>${booking.time ?? ""}</td>
      <td>${booking.price ?? ""}</td>
      <td><span class="status-badge ${displayStatus ?? ""}">${statusLabel}</span></td>
      <td class="row-actions">
        <button class="secondary-btn edit-btn">Düzenle</button>
        ${isActive ? '<button class="secondary-btn past-btn">Geçmiş Yap</button>' : ""}
        ${isActive ? '<button class="reject-btn cancel-btn">İptal Et</button>' : ""}
        ${isActive ? '<button class="reject-btn noshow-btn">Gelmedi</button>' : ""}
      </td>
    `;

    row.querySelector(".edit-btn").addEventListener("click", () => startEdit(booking));

    const pastBtn = row.querySelector(".past-btn");
    if (pastBtn) {
      pastBtn.addEventListener("click", () => updateBookingStatus(booking.id, "past"));
    }

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

  renderPagination(allPaginationEl, allPage, allBookingsData.length, PAGE_SIZE, (newPage) => {
    allPage = newPage;
    renderAllBookingsPage();
  });
}

allStatusFilterEl.addEventListener("change", loadAllBookings);

// --- Takvim: seçilen uzman + tarih için dolu/boş saatler ---
// Not: lib/pages/professionals_calendar.dart'taki uzman/saat listeleriyle
// aynı ("Fark etmez" akışındaki kısa isim tutarsızlığı ayrı bir konu).
const TIME_SLOTS = ["10:00 am", "11:00 am", "01:30 pm", "03:00 pm", "05:00 pm", "07:00 pm"];

const calendarSalonEl = document.getElementById("calendar-salon");
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
  const salonIdFilter = calendarSalonEl.value;
  const professional = calendarProfessionalEl.value;
  const dateIso = calendarDateEl.value;
  if (!dateIso || !salonIdFilter) return;

  calendarStatusEl.textContent = "Yükleniyor...";
  calendarSlotsEl.innerHTML = "";

  // 'waiting' + 'upcoming' birlikte kontrol ediliyor: onay bekleyen bir
  // randevu bile o saati dolu göstermeli (mobildeki getBookedTimes ile aynı mantık).
  // salonId filtresi olmadan, iki farklı şubede aynı isimli bir uzman varsa
  // dolu saatler birbirine karışırdı — bu yüzden şube burada da zorunlu.
  const q = query(
    collection(db, "bookings"),
    where("status", "in", ["waiting", "upcoming"]),
    where("salonId", "==", salonIdFilter),
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

calendarSalonEl.addEventListener("change", loadCalendar);
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
const newSalonEl = document.getElementById("new-salon");
const newSalonSearchEl = document.getElementById("new-salon-search");
const newSalonComboboxEl = document.getElementById("new-salon-combobox");
const newSalonOptionsEl = document.getElementById("new-salon-options");
const newProfessionalEl = document.getElementById("new-professional");
const newServiceEl = document.getElementById("new-service");
const newDateEl = document.getElementById("new-date");
const newTimeEl = document.getElementById("new-time");
const newStatusEl = document.getElementById("new-status");
const newSubmitBtnEl = document.getElementById("new-submit-btn");
const newCancelBtnEl = document.getElementById("new-cancel-btn");
const newFormStatusEl = document.getElementById("new-form-status");
let editingBookingId = null;
let editingOriginalStatus = null;

TIME_SLOTS.forEach((time) => {
  const option = document.createElement("option");
  option.value = time;
  option.textContent = time;
  newTimeEl.appendChild(option);
});

// admin_web/salonlar.html'de yönetilen şubeleri "Şube" arama kutusuna
// (combobox) doldurur; admin_web/uzmanlar.js'teki aynı desen (bkz.
// shared/combobox.js). Randevu, hangi uzman/hizmet seçilirse seçilsin,
// burada açıkça seçilen şubeye kaydedilir.
let allSalons = [];
const salonCombobox = attachCombobox({
  containerEl: newSalonComboboxEl,
  searchEl: newSalonSearchEl,
  hiddenEl: newSalonEl,
  optionsEl: newSalonOptionsEl,
  getItems: () => allSalons,
  getLabel: (salon) => salon.name ?? "",
  getId: (salon) => salon.id,
});

async function loadSalonNames() {
  const snapshot = await getDocs(collection(db, "salons"));
  allSalons = snapshot.docs
    .map((docSnap) => ({ id: docSnap.id, ...docSnap.data() }))
    .sort((a, b) => (a.name ?? "").localeCompare(b.name ?? ""));

  // Takvim sekmesindeki şube filtresi: aynı isimli bir uzman farklı
  // şubelerde çalışabildiği için, dolu/boş saat sorgusu artık bir şube
  // seçilmesini gerektiriyor (bkz. loadCalendar).
  const previous = calendarSalonEl.value;
  calendarSalonEl.innerHTML = "";
  allSalons.forEach((salon) => {
    const option = document.createElement("option");
    option.value = salon.id;
    option.textContent = salon.name ?? "";
    calendarSalonEl.appendChild(option);
  });
  if (allSalons.some((s) => s.id === previous)) calendarSalonEl.value = previous;
  if (calendarLoaded) await loadCalendar();
}

// Uzman ve hizmet dropdown'ları admin_web/uzmanlar.html ve hizmetler.html
// üzerinden yönetilen koleksiyonlardan geliyor; buradaki listeler sabit
// değil, ekle/düzenle/sil işlemleri (fiyat değişikliği dahil) buraya da yansır.
async function loadProfessionalOptions() {
  const snapshot = await getDocs(collection(db, "professionals"));
  const names = snapshot.docs.map((d) => d.data().name ?? "").filter(Boolean).sort();

  [newProfessionalEl, calendarProfessionalEl].forEach((selectEl) => {
    const previous = selectEl.value;
    selectEl.innerHTML = "";
    names.forEach((name) => {
      const option = document.createElement("option");
      option.value = name;
      option.textContent = name;
      selectEl.appendChild(option);
    });
    if (names.includes(previous)) selectEl.value = previous;
  });
}

async function loadServiceOptions() {
  const snapshot = await getDocs(collection(db, "services"));
  const services = snapshot.docs.map((d) => d.data()).sort((a, b) => (a.name ?? "").localeCompare(b.name ?? ""));

  newServiceEl.innerHTML = "";
  services.forEach((service) => {
    const option = document.createElement("option");
    option.value = service.name;
    option.dataset.price = service.price ?? "";
    option.textContent = `${service.name} - ${service.price ?? ""}`;
    newServiceEl.appendChild(option);
  });
}

loadSalonNames();
loadProfessionalOptions();
loadServiceOptions();

// Kullanıcı seçimi bir arama kutusu (combobox) ile yapılıyor: kullanıcı
// sayısı arttıkça uzun bir dropdown yerine isim/telefonla filtrelenebilen
// bir liste daha kullanışlı. allUsers/loadUserOptions/userLabel dosyanın
// başında tanımlı (Onay Kuyruğu'nda müşteri ismi göstermek için de kullanılıyor).
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
  editingOriginalStatus = null;
  newBookingFormEl.reset();
  newUserOptionsEl.hidden = true;
  salonCombobox.clear();
  newFormTitleEl.textContent = "Yeni Randevu";
  newSubmitBtnEl.textContent = "Randevu Oluştur";
  newCancelBtnEl.hidden = true;
}

function startEdit(booking) {
  editingBookingId = booking.id;
  editingOriginalStatus = booking.status ?? null;
  const user = allUsers.find((u) => u.id === booking.userId);
  newUserEl.value = booking.userId ?? "";
  newUserSearchEl.value = user ? userLabel(user) : "";
  salonCombobox.setValue(booking.salonId ?? "");
  newProfessionalEl.value = booking.professional ?? newProfessionalEl.value;
  newServiceEl.value = booking.service ?? newServiceEl.value;
  newDateEl.value = booking.dateIso;
  newTimeEl.value = booking.time ?? newTimeEl.value;
  newStatusEl.value = booking.status ?? "upcoming";
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
  const salonId = newSalonEl.value;
  if (!salonId) {
    newFormStatusEl.textContent = "Bir şube seçmelisin.";
    return;
  }

  newFormStatusEl.textContent = "Kaydediliyor...";

  const serviceOption = newServiceEl.selectedOptions[0];
  const salon = allSalons.find((s) => s.id === salonId)?.name ?? "";
  const data = {
    salonId,
    salon,
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
    // Sadece Onay Kuyruğu/Tüm Randevular'daki Onayla/İptal butonları değil,
    // bu formdan statü değişikliği yapılırsa da müşteri bildirim alsın.
    // Statü değişmediyse (sadece saat/uzman vb. düzenlendiyse) tekrar
    // bildirim oluşturulmasın diye önceki statüyle karşılaştırılıyor.
    if (data.status !== editingOriginalStatus) {
      await notifyBookingStatusChange(db, editingBookingId, data.status);
    }
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
