import { db } from "./shared/firebase.js";
import { mountSidebar, mountTopbar } from "./shared/layout.js";
import {
  collection,
  doc,
  getDocs,
  setDoc,
  updateDoc,
  deleteDoc,
} from "https://www.gstatic.com/firebasejs/10.13.2/firebase-firestore.js";

mountSidebar("sidebar-slot", "hizmetler");
mountTopbar("topbar-slot");

const listStatusEl = document.getElementById("list-status");
const listBodyEl = document.getElementById("services-body");

const formTitleEl = document.getElementById("form-title");
const formEl = document.getElementById("service-form");
const nameEl = document.getElementById("service-name");
const categoryEl = document.getElementById("service-category");
const durationEl = document.getElementById("service-duration");
const priceEl = document.getElementById("service-price");
const photoUrlEl = document.getElementById("service-photo-url");
const photoPreviewEl = document.getElementById("photo-preview");
const saveBtnEl = document.getElementById("save-btn");
const resetBtnEl = document.getElementById("reset-btn");
const deleteBtnEl = document.getElementById("delete-btn");
const formStatusEl = document.getElementById("form-status");

let services = [];
let editingId = null;

photoUrlEl.addEventListener("input", () => {
  photoPreviewEl.src = photoUrlEl.value.trim();
});

async function loadServices() {
  listStatusEl.textContent = "Yükleniyor...";
  const snapshot = await getDocs(collection(db, "services"));
  services = snapshot.docs.map((docSnap) => ({ id: docSnap.id, ...docSnap.data() }));
  services.sort((a, b) => (a.name ?? "").localeCompare(b.name ?? ""));
  renderList();
}

function renderList() {
  listBodyEl.innerHTML = "";

  if (services.length === 0) {
    listStatusEl.textContent = "Henüz hizmet eklenmedi.";
    return;
  }
  listStatusEl.textContent = `${services.length} hizmet.`;

  services.forEach((service) => {
    const row = document.createElement("tr");
    row.innerHTML = `
      <td>${service.photoUrl ? `<img class="table-thumb" src="${service.photoUrl}" alt="" />` : ""}</td>
      <td>${service.name ?? ""}</td>
      <td>${service.category ?? ""}</td>
      <td>${service.duration ?? ""} dk</td>
      <td>${service.price ?? ""}</td>
      <td class="row-actions">
        <button class="secondary-btn edit-btn">Düzenle</button>
        <button class="reject-btn delete-btn">Sil</button>
      </td>
    `;

    row.querySelector(".edit-btn").addEventListener("click", () => startEdit(service));
    row.querySelector(".delete-btn").addEventListener("click", () => deleteService(service));

    listBodyEl.appendChild(row);
  });
}

function resetForm() {
  editingId = null;
  formEl.reset();
  photoUrlEl.value = "";
  photoPreviewEl.src = "";
  formTitleEl.textContent = "Yeni Hizmet";
  saveBtnEl.textContent = "Hizmet Ekle";
  deleteBtnEl.hidden = true;
  formStatusEl.textContent = "";
}

function startEdit(service) {
  editingId = service.id;
  nameEl.value = service.name ?? "";
  categoryEl.value = service.category ?? "Nail";
  durationEl.value = service.duration ?? "";
  priceEl.value = service.price ?? "";
  photoUrlEl.value = service.photoUrl ?? "";
  photoPreviewEl.src = service.photoUrl ?? "";

  formTitleEl.textContent = "Hizmeti Düzenle";
  saveBtnEl.textContent = "Kaydet";
  deleteBtnEl.hidden = false;
  formStatusEl.textContent = "";
}

resetBtnEl.addEventListener("click", resetForm);

deleteBtnEl.addEventListener("click", async () => {
  if (!editingId) return;
  const service = services.find((s) => s.id === editingId);
  if (service) await deleteService(service);
});

async function deleteService(service) {
  const ok = window.confirm(`${service.name ?? "Bu hizmeti"} silmek istediğine emin misin?`);
  if (!ok) return;
  await deleteDoc(doc(db, "services", service.id));
  if (editingId === service.id) resetForm();
  await loadServices();
}

formEl.addEventListener("submit", async (e) => {
  e.preventDefault();

  const name = nameEl.value.trim();
  const category = categoryEl.value;
  const duration = parseInt(durationEl.value, 10);
  const price = priceEl.value.trim();

  if (!name || !price || Number.isNaN(duration)) {
    formStatusEl.textContent = "İsim, süre ve fiyat gerekli.";
    return;
  }

  saveBtnEl.disabled = true;
  formStatusEl.textContent = "Kaydediliyor...";

  const docRef = editingId ? doc(db, "services", editingId) : doc(collection(db, "services"));

  try {
    const data = { id: docRef.id, name, category, duration, price, photoUrl: photoUrlEl.value.trim() };

    if (editingId) {
      await updateDoc(docRef, data);
    } else {
      await setDoc(docRef, data);
    }

    formStatusEl.textContent = "Kaydedildi.";
    resetForm();
    await loadServices();
  } catch (err) {
    console.error(err);
    formStatusEl.textContent = `Kaydedilemedi: ${err.message ?? err}`;
  } finally {
    saveBtnEl.disabled = false;
  }
});

resetForm();
loadServices();
