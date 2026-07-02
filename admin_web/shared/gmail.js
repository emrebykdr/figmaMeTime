// Admin'in kendi Gmail hesabından, tarayıcı tabanlı Google OAuth ("token"
// akışı) ile e-posta gönderir. Client Secret kullanılmıyor, bu yüzden
// GOOGLE_CLIENT_ID'nin kod içinde/GitHub'da durması güvenlik sorunu değil
// (Google'ın OAuth Client ID'leri zaten herkese açık olacak şekilde
// tasarlanmıştır). İlk gönderimde Google'ın izin ekranı (popup) açılır;
// admin kendi hesabıyla "gönderme" iznini onaylar.
const GOOGLE_CLIENT_ID = "856573294991-pdcgodcp0r489vaqulohpovfideeenlp.apps.googleusercontent.com";
const GMAIL_SCOPE = "https://www.googleapis.com/auth/gmail.send";

let accessToken = null;

function loadGoogleIdentityServices() {
  return new Promise((resolve, reject) => {
    if (window.google?.accounts?.oauth2) {
      resolve();
      return;
    }
    const script = document.createElement("script");
    script.src = "https://accounts.google.com/gsi/client";
    script.onload = () => resolve();
    script.onerror = () => reject(new Error("Google Identity Services yüklenemedi."));
    document.head.appendChild(script);
  });
}

async function getAccessToken() {
  if (accessToken) return accessToken;

  await loadGoogleIdentityServices();

  return new Promise((resolve, reject) => {
    const tokenClient = google.accounts.oauth2.initTokenClient({
      client_id: GOOGLE_CLIENT_ID,
      scope: GMAIL_SCOPE,
      callback: (response) => {
        if (response.error) {
          reject(new Error(response.error));
          return;
        }
        accessToken = response.access_token;
        resolve(accessToken);
      },
    });
    tokenClient.requestAccessToken();
  });
}

function encodeSubject(subject) {
  return `=?utf-8?B?${btoa(unescape(encodeURIComponent(subject)))}?=`;
}

function buildRawEmail(to, subject, body) {
  const message = [
    `To: ${to}`,
    `Subject: ${encodeSubject(subject)}`,
    "Content-Type: text/plain; charset=utf-8",
    "",
    body,
  ].join("\r\n");

  return btoa(unescape(encodeURIComponent(message)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

export async function sendEmail(to, subject, body) {
  const token = await getAccessToken();
  const raw = buildRawEmail(to, subject, body);

  const response = await fetch("https://gmail.googleapis.com/gmail/v1/users/me/messages/send", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ raw }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    // Token geçersiz/süresi dolmuşsa (401/403) bir sonraki denemede
    // yeniden yetkilendirme istemek için sıfırlanıyor.
    accessToken = null;
    throw new Error(`Email gönderilemedi (${response.status}): ${errorText}`);
  }

  return response.json();
}
