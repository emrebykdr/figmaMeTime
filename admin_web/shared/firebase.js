// Tüm admin sayfalarının ortak Firebase bağlantısı. Her sayfa bunu import
// ederse firebaseConfig tek yerde durur (lib/firebase_options.dart -> web ile aynı proje).
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.13.2/firebase-app.js";
import { getFirestore } from "https://www.gstatic.com/firebasejs/10.13.2/firebase-firestore.js";

const firebaseConfig = {
  apiKey: "AIzaSyDCjzZtLzz3vVyLB2pUg6BwLJGFSY5ykdQ",
  authDomain: "metime-34cc7.firebaseapp.com",
  projectId: "metime-34cc7",
  storageBucket: "metime-34cc7.firebasestorage.app",
  messagingSenderId: "768603877453",
  appId: "1:768603877453:web:487e45179c87d83e516c04",
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
