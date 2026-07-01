import { initializeApp } from "https://www.gstatic.com/firebasejs/10.13.2/firebase-app.js";
import {
  getFirestore,
  collection,
  query,
  where,
  getDocs,
  doc,
  updateDoc,
} from "https://www.gstatic.com/firebasejs/10.13.2/firebase-firestore.js";

// lib/firebase_options.dart içindeki 'web' konfigürasyonuyla aynı proje.
const firebaseConfig = {
  apiKey: "AIzaSyDCjzZtLzz3vVyLB2pUg6BwLJGFSY5ykdQ",
  authDomain: "metime-34cc7.firebaseapp.com",
  projectId: "metime-34cc7",
  storageBucket: "metime-34cc7.firebasestorage.app",
  messagingSenderId: "768603877453",
  appId: "1:768603877453:web:487e45179c87d83e516c04",
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

const statusEl = document.getElementById("status");
const bodyEl = document.getElementById("bookings-body");
const statWaitingEl = document.getElementById("stat-waiting");
const statUpcomingEl = document.getElementById("stat-upcoming");
const statUsersEl = document.getElementById("stat-users");

async function refreshAll() {
  statusEl.textContent = "Yükleniyor...";

  const [waitingSnap, upcomingSnap, usersSnap] = await Promise.all([
    getDocs(query(collection(db, "bookings"), where("status", "==", "waiting"))),
    getDocs(query(collection(db, "bookings"), where("status", "==", "upcoming"))),
    getDocs(collection(db, "users")),
  ]);

  statWaitingEl.textContent = waitingSnap.size;
  statUpcomingEl.textContent = upcomingSnap.size;
  statUsersEl.textContent = usersSnap.size;

  renderWaitingBookings(waitingSnap);
}

function renderWaitingBookings(snapshot) {
  bodyEl.innerHTML = "";

  if (snapshot.empty) {
    statusEl.textContent = "Bekleyen randevu yok.";
    return;
  }

  statusEl.textContent = `${snapshot.size} bekleyen randevu.`;

  snapshot.forEach((docSnap) => {
    const booking = docSnap.data();
    const row = document.createElement("tr");
    row.innerHTML = `
      <td>${booking.salon ?? ""}</td>
      <td>${booking.professional ?? ""}</td>
      <td>${booking.service ?? ""}</td>
      <td>${booking.date ?? ""}</td>
      <td>${booking.time ?? ""}</td>
      <td>${booking.price ?? ""}</td>
      <td><button class="approve-btn">Onayla</button></td>
    `;

    const approveBtn = row.querySelector(".approve-btn");
    approveBtn.addEventListener("click", () => approveBooking(docSnap.id, approveBtn));

    bodyEl.appendChild(row);
  });
}

async function approveBooking(bookingId, buttonEl) {
  buttonEl.disabled = true;
  buttonEl.textContent = "Onaylanıyor...";
  await updateDoc(doc(db, "bookings", bookingId), { status: "upcoming" });
  await refreshAll();
}

refreshAll();
