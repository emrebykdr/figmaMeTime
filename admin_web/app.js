import { db } from "./shared/firebase.js";
import { mountSidebar, mountTopbar } from "./shared/layout.js";
import {
  collection,
  query,
  where,
  getDocs,
} from "https://www.gstatic.com/firebasejs/10.13.2/firebase-firestore.js";

mountSidebar("sidebar-slot", "dashboard");
mountTopbar("topbar-slot");

const statWaitingEl = document.getElementById("stat-waiting");
const statUpcomingEl = document.getElementById("stat-upcoming");
const statUsersEl = document.getElementById("stat-users");

async function loadOverview() {
  const [waitingSnap, upcomingSnap, usersSnap] = await Promise.all([
    getDocs(query(collection(db, "bookings"), where("status", "==", "waiting"))),
    getDocs(query(collection(db, "bookings"), where("status", "==", "upcoming"))),
    getDocs(collection(db, "users")),
  ]);

  statWaitingEl.textContent = waitingSnap.size;
  statUpcomingEl.textContent = upcomingSnap.size;
  statUsersEl.textContent = usersSnap.size;
}

loadOverview();
