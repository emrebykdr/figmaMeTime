import {
  isLoggedIn,
  markLoggedIn,
  isProfessionalLoggedIn,
  markProfessionalLoggedIn,
} from "./shared/auth.js?v=4";
import { db } from "./shared/firebase.js?v=2";
import {
  doc,
  getDoc,
  collection,
  query,
  where,
  getDocs,
} from "https://www.gstatic.com/firebasejs/10.13.2/firebase-firestore.js";

// admin_web/erisim.html'den değiştirilebilir. Doküman henüz oluşturulmadıysa
// (ilk çalıştırma) bu sabit değerlere düşülür, böylece geçiş hiçbir şeyi
// kırmaz.
const DEFAULT_ADMIN_EMAIL = "admin@metime.com";
const DEFAULT_ADMIN_PASSWORD = "emre2005";

// Zaten giriş yapılmışsa (admin veya uzman) login ekranını atla.
if (isLoggedIn()) {
  window.location.href = "index.html";
} else if (isProfessionalLoggedIn()) {
  window.location.href = "uzman-panel.html";
}

const formEl = document.getElementById("login-form");
const emailEl = document.getElementById("login-email");
const passwordEl = document.getElementById("login-password");
const errorEl = document.getElementById("login-error");

async function getAdminCredentials() {
  const snapshot = await getDoc(doc(db, "adminConfig", "credentials"));
  if (!snapshot.exists()) {
    return { email: DEFAULT_ADMIN_EMAIL, password: DEFAULT_ADMIN_PASSWORD };
  }
  const data = snapshot.data();
  return {
    email: data.email || DEFAULT_ADMIN_EMAIL,
    password: data.password || DEFAULT_ADMIN_PASSWORD,
  };
}

// Aynı form hem admin hem uzman girişini kabul eder: önce admin bilgileriyle
// karşılaştırılır, eşleşmezse professionals koleksiyonunda email/password
// eşleşmesi aranır (bkz. admin_web/erisim.html -> uzmanlara atanan giriş
// bilgileri).
async function tryProfessionalLogin(email, password) {
  const snapshot = await getDocs(
    query(collection(db, "professionals"), where("email", "==", email))
  );
  if (snapshot.empty) return false;

  const professional = { id: snapshot.docs[0].id, ...snapshot.docs[0].data() };
  if (professional.password !== password) return false;

  markProfessionalLoggedIn(professional.id, professional.name ?? "", professional.salonId ?? "");
  return true;
}

formEl.addEventListener("submit", async (e) => {
  e.preventDefault();
  const email = emailEl.value.trim();
  const password = passwordEl.value;
  errorEl.textContent = "";

  const credentials = await getAdminCredentials();
  if (email === credentials.email && password === credentials.password) {
    markLoggedIn();
    window.location.href = "index.html";
    return;
  }

  if (await tryProfessionalLogin(email, password)) {
    window.location.href = "uzman-panel.html";
    return;
  }

  errorEl.textContent = "E-posta veya şifre hatalı.";
});
