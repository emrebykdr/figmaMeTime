// Bu statik sitede gerçek bir cron/scheduled job yok, yani hiçbir şey
// arka planda "tarihi geçen randevuları past yap" diye çalışmıyor.
// Bunun yerine syncPastBookings(db), shared/firebase.js üzerinden her admin
// sayfası açıldığında bir kere tetiklenir: tarihi geçmiş 'upcoming' kayıtları
// bulup Firestore'da gerçekten status: 'past' olarak günceller.
// effectiveStatus() ise senkron henüz çalışmadığı an (ör. sayfa yeni
// açıldı, sorgu daha dönmedi) için görüntülemede aynı sonucu veren bir
// güvenlik ağı olarak kalıyor.
import {
  collection,
  query,
  where,
  getDocs,
  writeBatch,
} from "https://www.gstatic.com/firebasejs/10.13.2/firebase-firestore.js";

export function todayIso() {
  const now = new Date();
  const month = String(now.getMonth() + 1).padStart(2, "0");
  const day = String(now.getDate()).padStart(2, "0");
  return `${now.getFullYear()}-${month}-${day}`;
}

export function effectiveStatus(booking) {
  if (booking.status === "upcoming" && booking.dateIso && booking.dateIso < todayIso()) {
    return "past";
  }
  return booking.status;
}

export async function syncPastBookings(db) {
  const snapshot = await getDocs(query(collection(db, "bookings"), where("status", "==", "upcoming")));
  const today = todayIso();
  const overdue = snapshot.docs.filter((docSnap) => {
    const dateIso = docSnap.data().dateIso;
    return dateIso && dateIso < today;
  });

  if (overdue.length === 0) return;

  const chunkSize = 400;
  for (let i = 0; i < overdue.length; i += chunkSize) {
    const batch = writeBatch(db);
    overdue.slice(i, i + chunkSize).forEach((docSnap) => batch.update(docSnap.ref, { status: "past" }));
    await batch.commit();
  }
}
