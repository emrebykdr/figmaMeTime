import { db } from "./shared/firebase.js?v=2";
import { mountSidebar, mountTopbar } from "./shared/layout.js?v=4";
import { requireLogin } from "./shared/auth.js?v=2";
import {
  collection,
  doc,
  getDocs,
  setDoc,
  serverTimestamp,
} from "https://www.gstatic.com/firebasejs/10.13.2/firebase-firestore.js";

requireLogin();

mountSidebar("sidebar-slot", "salonlar");
mountTopbar("topbar-slot");

const listStatusEl = document.getElementById("list-status");
const listBodyEl = document.getElementById("salons-body");

const formStatusEl = document.getElementById("form-status");
const formEl = document.getElementById("salon-form");
const nameEl = document.getElementById("salon-name");
const addressEl = document.getElementById("salon-address");
const phoneEl = document.getElementById("salon-phone");
const emailEl = document.getElementById("salon-email");
const priceTierEl = document.getElementById("salon-price-tier");
const photoUrlEl = document.getElementById("salon-photo-url");
const photoPreviewEl = document.getElementById("photo-preview");
const saveBtnEl = document.getElementById("save-btn");

photoUrlEl.addEventListener("input", () => {
  photoPreviewEl.src = photoUrlEl.value.trim();
});

// Combobox'larda (uzmanlar.js/hizmetler.js/randevular.js -> Şube) sadece isim
// göründüğü için, aynı isimli iki şube olursa hangisinin seçildiği
// belirsizleşir. Bu yüzden yeni şube eklerken isim tekilliği kontrol edilir.
let allSalons = [];

// Her şube satırında kaç uzman/hizmet/randevuya sahip olduğunu göstermek
// için, salon-detay.html'e gitmeden önce hızlı bir özet verir.
function countBySalonId(docs) {
  const counts = {};
  docs.forEach((data) => {
    if (!data.salonId) return;
    counts[data.salonId] = (counts[data.salonId] ?? 0) + 1;
  });
  return counts;
}

async function loadSalons() {
  listStatusEl.textContent = "Yükleniyor...";

  const [salonsSnap, professionalsSnap, servicesSnap, bookingsSnap] = await Promise.all([
    getDocs(collection(db, "salons")),
    getDocs(collection(db, "professionals")),
    getDocs(collection(db, "services")),
    getDocs(collection(db, "bookings")),
  ]);

  allSalons = salonsSnap.docs
    .map((docSnap) => ({ id: docSnap.id, ...docSnap.data() }))
    .sort((a, b) => (a.name ?? "").localeCompare(b.name ?? ""));

  const professionalCounts = countBySalonId(professionalsSnap.docs.map((d) => d.data()));
  const serviceCounts = countBySalonId(servicesSnap.docs.map((d) => d.data()));
  const bookingCounts = countBySalonId(bookingsSnap.docs.map((d) => d.data()));

  renderList(allSalons, professionalCounts, serviceCounts, bookingCounts);
}

function renderList(salons, professionalCounts, serviceCounts, bookingCounts) {
  listBodyEl.innerHTML = "";

  if (salons.length === 0) {
    listStatusEl.textContent = "Henüz şube eklenmedi.";
    return;
  }
  listStatusEl.textContent = `${salons.length} şube.`;

  salons.forEach((salon) => {
    const row = document.createElement("tr");
    row.innerHTML = `
      <td>${salon.name ?? ""}</td>
      <td>${salon.address ?? ""}</td>
      <td>${salon.phone ?? ""}</td>
      <td>${professionalCounts[salon.id] ?? 0}</td>
      <td>${serviceCounts[salon.id] ?? 0}</td>
      <td>${bookingCounts[salon.id] ?? 0}</td>
      <td><a class="secondary-btn" href="salon-detay.html?id=${salon.id}">Detay</a></td>
    `;
    listBodyEl.appendChild(row);
  });
}

formEl.addEventListener("submit", async (e) => {
  e.preventDefault();

  const name = nameEl.value.trim();
  if (!name) {
    formStatusEl.textContent = "Salon adı gerekli.";
    return;
  }
  if (allSalons.some((s) => (s.name ?? "").trim().toLowerCase() === name.toLowerCase())) {
    formStatusEl.textContent = "Bu isimde bir şube zaten var. Farklı bir isim seç.";
    return;
  }

  saveBtnEl.disabled = true;
  formStatusEl.textContent = "Kaydediliyor...";

  try {
    const docRef = doc(collection(db, "salons"));
    await setDoc(docRef, {
      id: docRef.id,
      name,
      address: addressEl.value.trim(),
      phone: phoneEl.value.trim(),
      email: emailEl.value.trim(),
      priceTier: priceTierEl.value.trim(),
      photoUrl: photoUrlEl.value.trim(),
      createdAt: serverTimestamp(),
    });

    formStatusEl.textContent = "Şube eklendi.";
    formEl.reset();
    photoPreviewEl.src = "";
    await loadSalons();
  } catch (err) {
    console.error(err);
    formStatusEl.textContent = `Kaydedilemedi: ${err.message ?? err}`;
  } finally {
    saveBtnEl.disabled = false;
  }
});

loadSalons();
