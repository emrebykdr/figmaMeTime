// Basit istemci tarafı "giriş" kontrolü. Gerçek bir kimlik doğrulama
// sistemi değil (Firebase Authentication vs.) -- kimse Firestore/Storage
// için ek Console kurulumu yapmak istemediği için bu şekilde tutuldu.
// Sadece admin panelinin URL'sini bilen sıradan birinin rastgele
// dolaşmasını engelleyen basit bir kapı; tarayıcı konsolundan
// localStorage'a elle 'true' yazılarak atlatılabilir.
const STORAGE_KEY = "adminLoggedIn";

// Her admin sayfasının JS dosyasının en başında çağrılır. Giriş
// yapılmamışsa login.html'e yönlendirir.
export function requireLogin() {
  const isLoggedIn = localStorage.getItem(STORAGE_KEY) === "true";
  if (!isLoggedIn) {
    window.location.href = "login.html";
  }
  return isLoggedIn;
}

export function isLoggedIn() {
  return localStorage.getItem(STORAGE_KEY) === "true";
}

export function markLoggedIn() {
  localStorage.setItem(STORAGE_KEY, "true");
}

export function logout() {
  localStorage.removeItem(STORAGE_KEY);
  window.location.href = "login.html";
}

// --- Uzman (staff) oturumu: admin oturumundan tamamen ayrı, kendi
// localStorage anahtarlarını kullanır. Bir uzman panelde giriş yapmışken
// admin sayfalarına, admin girişliyken de uzman paneline erişemez (ikisi
// birbirinden bağımsız bayraklar).
const PROFESSIONAL_STORAGE_KEY = "professionalLoggedIn";
const PROFESSIONAL_ID_KEY = "currentProfessionalId";
const PROFESSIONAL_NAME_KEY = "currentProfessionalName";
const PROFESSIONAL_SALON_ID_KEY = "currentProfessionalSalonId";

export function isProfessionalLoggedIn() {
  return localStorage.getItem(PROFESSIONAL_STORAGE_KEY) === "true";
}

// Her uzman paneli sayfasının JS dosyasının en başında çağrılır. Giriş
// yapılmamışsa login.html'e yönlendirir (admin ve uzman girişi artık aynı
// formu paylaşıyor, bkz. admin_web/login.js).
export function requireProfessionalLogin() {
  const loggedIn = isProfessionalLoggedIn();
  if (!loggedIn) {
    window.location.href = "login.html";
    return null;
  }
  return {
    id: localStorage.getItem(PROFESSIONAL_ID_KEY),
    name: localStorage.getItem(PROFESSIONAL_NAME_KEY),
    salonId: localStorage.getItem(PROFESSIONAL_SALON_ID_KEY),
  };
}

export function markProfessionalLoggedIn(id, name, salonId) {
  localStorage.setItem(PROFESSIONAL_STORAGE_KEY, "true");
  localStorage.setItem(PROFESSIONAL_ID_KEY, id);
  localStorage.setItem(PROFESSIONAL_NAME_KEY, name);
  localStorage.setItem(PROFESSIONAL_SALON_ID_KEY, salonId ?? "");
}

export function professionalLogout() {
  localStorage.removeItem(PROFESSIONAL_STORAGE_KEY);
  localStorage.removeItem(PROFESSIONAL_ID_KEY);
  localStorage.removeItem(PROFESSIONAL_NAME_KEY);
  localStorage.removeItem(PROFESSIONAL_SALON_ID_KEY);
  window.location.href = "login.html";
}
