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
