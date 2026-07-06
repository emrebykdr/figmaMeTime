import { db } from "./shared/firebase.js?v=2";
import { mountSidebar, mountTopbar } from "./shared/layout.js?v=5";
import { requireLogin } from "./shared/auth.js?v=4";
import {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  collection,
  getDocs,
} from "https://www.gstatic.com/firebasejs/10.13.2/firebase-firestore.js";

requireLogin();

mountSidebar("sidebar-slot", "erisim");
mountTopbar("topbar-slot");

const DEFAULT_ADMIN_EMAIL = "admin@metime.com";
const DEFAULT_ADMIN_PASSWORD = "emre2005";

// --- Admin Girişi ---
const adminFormEl = document.getElementById("admin-form");
const adminEmailEl = document.getElementById("admin-email");
const adminPasswordEl = document.getElementById("admin-password");
const adminFormStatusEl = document.getElementById("admin-form-status");

async function loadAdminCredentials() {
  const snapshot = await getDoc(doc(db, "adminConfig", "credentials"));
  const data = snapshot.exists() ? snapshot.data() : {};
  adminEmailEl.value = data.email || DEFAULT_ADMIN_EMAIL;
  adminPasswordEl.value = data.password || DEFAULT_ADMIN_PASSWORD;
}

adminFormEl.addEventListener("submit", async (e) => {
  e.preventDefault();
  const email = adminEmailEl.value.trim();
  const password = adminPasswordEl.value;
  if (!email || !password) {
    adminFormStatusEl.textContent = "E-posta ve şifre gerekli.";
    return;
  }

  adminFormStatusEl.textContent = "Kaydediliyor...";
  await setDoc(doc(db, "adminConfig", "credentials"), { email, password });
  adminFormStatusEl.textContent = "Kaydedildi.";
});

// --- Uzman Girişleri ---
const listStatusEl = document.getElementById("list-status");
const listBodyEl = document.getElementById("professionals-body");
let professionals = [];

async function loadProfessionals() {
  listStatusEl.textContent = "Yükleniyor...";
  const snapshot = await getDocs(collection(db, "professionals"));
  professionals = snapshot.docs
    .map((docSnap) => ({ id: docSnap.id, ...docSnap.data() }))
    .sort((a, b) => (a.name ?? "").localeCompare(b.name ?? ""));
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
    const row = document.createElement("tr");
    row.innerHTML = `
      <td>${prof.name ?? ""}</td>
      <td><input type="email" class="prof-email" value="${prof.email ?? ""}" /></td>
      <td><input type="text" class="prof-password" value="${prof.password ?? ""}" /></td>
      <td class="row-actions">
        <button class="secondary-btn save-btn">Kaydet</button>
      </td>
    `;

    const emailInput = row.querySelector(".prof-email");
    const passwordInput = row.querySelector(".prof-password");
    row.querySelector(".save-btn").addEventListener("click", () =>
      saveProfessionalCredentials(prof, emailInput.value.trim(), passwordInput.value)
    );

    listBodyEl.appendChild(row);
  });
}

// Aynı email'in iki uzmana verilmesi, login.js'teki uzman girişi sorgusunu
// belirsizleştirir (hangi uzmana ait olduğu karışır); bu yüzden kaydetmeden
// önce tekillik kontrol edilir (bkz. admin_web/salonlar.js'teki aynı desen).
async function saveProfessionalCredentials(prof, email, password) {
  if (!email || !password) {
    listStatusEl.textContent = "E-posta ve şifre gerekli.";
    return;
  }
  const duplicate = professionals.some(
    (p) => p.id !== prof.id && (p.email ?? "").toLowerCase() === email.toLowerCase()
  );
  if (duplicate) {
    listStatusEl.textContent = `Bu e-posta zaten başka bir uzmana atanmış.`;
    return;
  }

  listStatusEl.textContent = "Kaydediliyor...";
  await updateDoc(doc(db, "professionals", prof.id), { email, password });
  prof.email = email;
  prof.password = password;
  listStatusEl.textContent = "Kaydedildi.";
}

loadAdminCredentials();
loadProfessionals();
