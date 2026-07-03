import {
  doc,
  getDoc,
  collection,
  addDoc,
  serverTimestamp,
} from "https://www.gstatic.com/firebasejs/10.13.2/firebase-firestore.js";

const STATUS_MESSAGES = {
  upcoming: { type: "confirmed", title: "Randevunuz onaylandı" },
  cancelled: { type: "cancelled", title: "Randevunuz iptal edildi" },
};

// Randevu statüsü admin panelinden değiştirildiğinde (onayla/reddet/iptal),
// mobil uygulamadaki Bildirimler sayfasında görünmesi için notifications
// koleksiyonuna bir kayıt düşer. past/no-show/waiting geçişlerinde bildirim
// oluşturulmaz (henüz istenmiyor).
export async function notifyBookingStatusChange(db, bookingId, status) {
  const meta = STATUS_MESSAGES[status];
  if (!meta) return;

  const bookingSnap = await getDoc(doc(db, "bookings", bookingId));
  if (!bookingSnap.exists()) return;
  const booking = bookingSnap.data();
  if (!booking.userId) return;

  await addDoc(collection(db, "notifications"), {
    userId: booking.userId,
    bookingId,
    type: meta.type,
    title: meta.title,
    body: `${booking.service ?? "Randevunuz"} - ${booking.date ?? ""} ${booking.time ?? ""}`,
    read: false,
    createdAt: serverTimestamp(),
  });
}
