import { db } from "./shared/firebase.js?v=2";
import { mountSidebar, mountTopbar } from "./shared/layout.js?v=4";
import { requireLogin } from "./shared/auth.js?v=2";
import { PAGE_SIZE, renderPagination } from "./shared/pagination.js?v=2";
import { collection, getDocs } from "https://www.gstatic.com/firebasejs/10.13.2/firebase-firestore.js";

requireLogin();

mountSidebar("sidebar-slot", "kullanicilar");
mountTopbar("topbar-slot");

const searchEl = document.getElementById("user-search");
const listStatusEl = document.getElementById("list-status");
const bodyEl = document.getElementById("users-body");
const paginationEl = document.getElementById("users-pagination");

let allUsers = [];
let filteredUsers = [];
let page = 1;

function formatDate(timestamp) {
  if (!timestamp?.toDate) return "-";
  return timestamp.toDate().toLocaleDateString("tr-TR");
}

async function loadUsers() {
  listStatusEl.textContent = "Yükleniyor...";
  const snapshot = await getDocs(collection(db, "users"));
  allUsers = snapshot.docs.map((docSnap) => ({ id: docSnap.id, ...docSnap.data() }));
  allUsers.sort((a, b) => (a.fullName ?? "").localeCompare(b.fullName ?? ""));
  applyFilter();
}

function applyFilter() {
  const text = searchEl.value.trim().toLowerCase();
  filteredUsers = text
    ? allUsers.filter(
        (u) =>
          (u.fullName ?? "").toLowerCase().includes(text) ||
          (u.phone ?? "").toLowerCase().includes(text) ||
          (u.email ?? "").toLowerCase().includes(text)
      )
    : allUsers;
  page = 1;
  renderPage();
}

function renderPage() {
  bodyEl.innerHTML = "";

  if (filteredUsers.length === 0) {
    listStatusEl.textContent = "Kayıt yok.";
    paginationEl.innerHTML = "";
    return;
  }

  listStatusEl.textContent = `${filteredUsers.length} kullanıcı.`;

  const start = (page - 1) * PAGE_SIZE;
  filteredUsers.slice(start, start + PAGE_SIZE).forEach((user) => {
    const row = document.createElement("tr");
    const isBlocked = user.accountBlocked === true;
    const isRestricted = user.bookingRestricted === true;
    // Hesap engeli, randevu kısıtlamasından daha ağır bir durum olduğu için önce o gösterilir.
    const statusLabel = isBlocked ? "Hesap Engelli" : isRestricted ? "Randevu Kısıtlı" : "Aktif";
    const statusClass = isBlocked || isRestricted ? "cancelled" : "upcoming";
    row.innerHTML = `
      <td>${user.fullName ?? "İsimsiz"}</td>
      <td>${user.phone ?? "-"}</td>
      <td>${user.email ?? "-"}</td>
      <td>${formatDate(user.createdAt)}</td>
      <td><span class="status-badge ${statusClass}">${statusLabel}</span></td>
      <td><a class="secondary-btn" href="kullanici-detay.html?id=${user.id}">Detay</a></td>
    `;
    bodyEl.appendChild(row);
  });

  renderPagination(paginationEl, page, filteredUsers.length, PAGE_SIZE, (newPage) => {
    page = newPage;
    renderPage();
  });
}

searchEl.addEventListener("input", applyFilter);

loadUsers();
