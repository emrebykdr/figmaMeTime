import { db } from "./shared/firebase.js?v=2";
import { mountSidebar, mountTopbar } from "./shared/layout.js?v=4";
import { requireLogin } from "./shared/auth.js?v=2";
import { attachCombobox } from "./shared/combobox.js?v=2";
import {
  collection,
  doc,
  getDocs,
  setDoc,
  updateDoc,
  deleteDoc,
  serverTimestamp,
} from "https://www.gstatic.com/firebasejs/10.13.2/firebase-firestore.js";

requireLogin();

mountSidebar("sidebar-slot", "uzmanlar");
mountTopbar("topbar-slot");

// lib/pages/professionals_calendar.dart'taki _availableTimes ile aynı liste.
const TIME_SLOTS = ["10:00 am", "11:00 am", "01:30 pm", "03:00 pm", "05:00 pm", "07:00 pm"];
// JS Date.getDay() sırasıyla değil, haftanın doğal (Pzt başlangıçlı) görünümüyle.
const DAY_ORDER = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"];
const DAY_LABELS = { mon: "Pzt", tue: "Sal", wed: "Çar", thu: "Per", fri: "Cum", sat: "Cmt", sun: "Paz" };

const listStatusEl = document.getElementById("list-status");
const listBodyEl = document.getElementById("professionals-body");

const formTitleEl = document.getElementById("form-title");
const formEl = document.getElementById("professional-form");
const nameEl = document.getElementById("prof-name");
const salonEl = document.getElementById("prof-salon");
const salonSearchEl = document.getElementById("prof-salon-search");
const salonComboboxEl = document.getElementById("prof-salon-combobox");
const salonOptionsEl = document.getElementById("prof-salon-options");
const roleEl = document.getElementById("prof-role");
const ratingEl = document.getElementById("prof-rating");
const photoUrlEl = document.getElementById("prof-photo-url");
const photoPreviewEl = document.getElementById("photo-preview");
const availabilityBodyEl = document.getElementById("availability-body");
const dayOffInputEl = document.getElementById("day-off-input");
const addDayOffBtnEl = document.getElementById("add-day-off-btn");
const dayOffListEl = document.getElementById("day-off-list");
const saveBtnEl = document.getElementById("save-btn");
const resetBtnEl = document.getElementById("reset-btn");
const deleteBtnEl = document.getElementById("delete-btn");
const formStatusEl = document.getElementById("form-status");

let professionals = [];
let editingId = null;
let daysOff = [];
let allSalons = [];
let salonNameById = {};

// admin_web/salonlar.html'de yönetilen şubeleri "Şube" arama kutusuna
// (combobox) doldurur; admin_web/randevular.js'teki Kullanıcı combobox'ıyla
// aynı davranış (bkz. shared/combobox.js).
const salonCombobox = attachCombobox({
  containerEl: salonComboboxEl,
  searchEl: salonSearchEl,
  hiddenEl: salonEl,
  optionsEl: salonOptionsEl,
  getItems: () => allSalons,
  getLabel: (salon) => salon.name ?? "",
  getId: (salon) => salon.id,
});

async function loadSalonOptions() {
  const snapshot = await getDocs(collection(db, "salons"));
  allSalons = snapshot.docs
    .map((docSnap) => ({ id: docSnap.id, ...docSnap.data() }))
    .sort((a, b) => (a.name ?? "").localeCompare(b.name ?? ""));
  salonNameById = Object.fromEntries(allSalons.map((s) => [s.id, s.name ?? ""]));
}

// --- Haftalık müsaitlik tablosu (6 saat x 7 gün checkbox grid'i) ---
function buildAvailabilityGrid() {
  availabilityBodyEl.innerHTML = "";
  TIME_SLOTS.forEach((time, timeIndex) => {
    const row = document.createElement("tr");
    const dayCells = DAY_ORDER.map(
      (day) => `<td><input type="checkbox" id="avail-${day}-${timeIndex}" /></td>`
    ).join("");
    row.innerHTML = `<td>${time}</td>${dayCells}`;
    availabilityBodyEl.appendChild(row);
  });
}
buildAvailabilityGrid();

function getWorkingHoursFromForm() {
  const workingHours = {};
  DAY_ORDER.forEach((day) => {
    workingHours[day] = TIME_SLOTS.filter(
      (_, timeIndex) => document.getElementById(`avail-${day}-${timeIndex}`).checked
    );
  });
  return workingHours;
}

function setWorkingHoursToForm(workingHours) {
  DAY_ORDER.forEach((day) => {
    // Kayıtlı çalışma saati yoksa (yeni uzman), varsayılan olarak her saat müsait gösterilir.
    const slots = workingHours?.[day] ?? TIME_SLOTS;
    TIME_SLOTS.forEach((time, timeIndex) => {
      document.getElementById(`avail-${day}-${timeIndex}`).checked = slots.includes(time);
    });
  });
}

// --- İzin/tatil günleri ---
function renderDaysOff() {
  dayOffListEl.innerHTML = "";
  daysOff
    .slice()
    .sort()
    .forEach((iso) => {
      const pill = document.createElement("span");
      pill.className = "day-off-pill";
      pill.innerHTML = `${iso} <button type="button" data-date="${iso}">&times;</button>`;
      pill.querySelector("button").addEventListener("click", () => {
        daysOff = daysOff.filter((d) => d !== iso);
        renderDaysOff();
      });
      dayOffListEl.appendChild(pill);
    });
}

addDayOffBtnEl.addEventListener("click", () => {
  const iso = dayOffInputEl.value;
  if (!iso || daysOff.includes(iso)) return;
  daysOff.push(iso);
  dayOffInputEl.value = "";
  renderDaysOff();
});

// --- Fotoğraf: dosya yükleme yerine doğrudan URL yapıştırılıyor (Storage kurulumu gerekmez). ---
photoUrlEl.addEventListener("input", () => {
  photoPreviewEl.src = photoUrlEl.value.trim();
});

// --- Liste ---
async function loadProfessionals() {
  listStatusEl.textContent = "Yükleniyor...";
  const snapshot = await getDocs(collection(db, "professionals"));
  professionals = snapshot.docs.map((docSnap) => ({ id: docSnap.id, ...docSnap.data() }));
  professionals.sort((a, b) => (a.name ?? "").localeCompare(b.name ?? ""));
  renderList();
}

function renderList() {
  listBodyEl.innerHTML = "";

  if (professionals.length === 0) {
    listStatusEl.textContent = "Henüz uzman eklenmedi.";
    return;
  }
  listStatusEl.textContent = `${professionals.length} uzman.`;

  professionals.forEach((prof) => {
    const workingDayCount = DAY_ORDER.filter((day) => (prof.workingHours?.[day]?.length ?? 0) > 0).length;
    const daysOffCount = prof.daysOff?.length ?? 0;

    const row = document.createElement("tr");
    row.innerHTML = `
      <td>${prof.photoUrl ? `<img class="table-thumb" src="${prof.photoUrl}" alt="" />` : ""}</td>
      <td>${prof.name ?? ""}</td>
      <td>${salonNameById[prof.salonId] ?? ""}</td>
      <td>${prof.role ?? ""}</td>
      <td>${prof.rating ?? ""}</td>
      <td>${workingDayCount}/7</td>
      <td>${daysOffCount}</td>
      <td class="row-actions">
        <button class="secondary-btn edit-btn">Düzenle</button>
        <button class="reject-btn delete-btn">Sil</button>
      </td>
    `;

    row.querySelector(".edit-btn").addEventListener("click", () => startEdit(prof));
    row.querySelector(".delete-btn").addEventListener("click", () => deleteProfessional(prof));

    listBodyEl.appendChild(row);
  });
}

// --- Form: ekle / düzenle / sil ---
function resetForm() {
  editingId = null;
  daysOff = [];
  formEl.reset();
  salonCombobox.clear();
  ratingEl.value = "5.0";
  photoUrlEl.value = "";
  photoPreviewEl.src = "";
  renderDaysOff();
  setWorkingHoursToForm(null);
  formTitleEl.textContent = "Yeni Uzman";
  saveBtnEl.textContent = "Uzman Ekle";
  deleteBtnEl.hidden = true;
  formStatusEl.textContent = "";
}

function startEdit(prof) {
  editingId = prof.id;
  daysOff = [...(prof.daysOff ?? [])];

  nameEl.value = prof.name ?? "";
  salonCombobox.setValue(prof.salonId ?? "");
  roleEl.value = prof.role ?? "";
  ratingEl.value = prof.rating ?? "5.0";
  photoUrlEl.value = prof.photoUrl ?? "";
  photoPreviewEl.src = prof.photoUrl ?? "";
  renderDaysOff();
  setWorkingHoursToForm(prof.workingHours);

  formTitleEl.textContent = "Uzmanı Düzenle";
  saveBtnEl.textContent = "Kaydet";
  deleteBtnEl.hidden = false;
  formStatusEl.textContent = "";
}

resetBtnEl.addEventListener("click", resetForm);

deleteBtnEl.addEventListener("click", async () => {
  if (!editingId) return;
  const prof = professionals.find((p) => p.id === editingId);
  if (prof) await deleteProfessional(prof);
});

async function deleteProfessional(prof) {
  const ok = window.confirm(`${prof.name ?? "Bu uzmanı"} silmek istediğine emin misin?`);
  if (!ok) return;
  await deleteDoc(doc(db, "professionals", prof.id));
  if (editingId === prof.id) resetForm();
  await loadProfessionals();
}

formEl.addEventListener("submit", async (e) => {
  e.preventDefault();

  const name = nameEl.value.trim();
  const role = roleEl.value.trim();
  const rating = parseFloat(ratingEl.value);
  if (!name || !role || Number.isNaN(rating)) {
    formStatusEl.textContent = "İsim, rol ve rating gerekli.";
    return;
  }
  if (!salonEl.value) {
    formStatusEl.textContent = "Bir şube seçmelisin.";
    return;
  }

  saveBtnEl.disabled = true;
  formStatusEl.textContent = "Kaydediliyor...";

  const docRef = editingId ? doc(db, "professionals", editingId) : doc(collection(db, "professionals"));

  try {
    const data = {
      id: docRef.id,
      name,
      salonId: salonEl.value,
      role,
      rating,
      photoUrl: photoUrlEl.value.trim(),
      workingHours: getWorkingHoursFromForm(),
      daysOff,
    };

    if (editingId) {
      await updateDoc(docRef, data);
    } else {
      await setDoc(docRef, { ...data, createdAt: serverTimestamp() });
    }

    formStatusEl.textContent = "Kaydedildi.";
    resetForm();
    await loadProfessionals();
  } catch (err) {
    console.error(err);
    formStatusEl.textContent = `Kaydedilemedi: ${err.message ?? err}`;
  } finally {
    saveBtnEl.disabled = false;
  }
});

resetForm();
loadSalonOptions().then(loadProfessionals);
