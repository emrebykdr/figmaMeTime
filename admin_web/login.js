import { isLoggedIn, markLoggedIn } from "./shared/auth.js?v=2";

const ADMIN_EMAIL = "admin@metime.com";
const ADMIN_PASSWORD = "emre2005";

// Zaten giriş yapılmışsa login ekranını atla.
if (isLoggedIn()) {
  window.location.href = "index.html";
}

const formEl = document.getElementById("login-form");
const emailEl = document.getElementById("login-email");
const passwordEl = document.getElementById("login-password");
const errorEl = document.getElementById("login-error");

formEl.addEventListener("submit", (e) => {
  e.preventDefault();
  const email = emailEl.value.trim();
  const password = passwordEl.value;

  if (email === ADMIN_EMAIL && password === ADMIN_PASSWORD) {
    markLoggedIn();
    window.location.href = "index.html";
  } else {
    errorEl.textContent = "E-posta veya şifre hatalı.";
  }
});
