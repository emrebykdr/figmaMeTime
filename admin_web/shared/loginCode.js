import { doc, getDoc, setDoc } from "https://www.gstatic.com/firebasejs/10.13.2/firebase-firestore.js";

export const CODE_LIFETIME_MS = 10 * 60 * 1000;

export function generateLoginCode() {
  return String(Math.floor(10000 + Math.random() * 90000));
}

export function formatRemaining(ms) {
  const totalSeconds = Math.max(0, Math.ceil(ms / 1000));
  const minutes = String(Math.floor(totalSeconds / 60)).padStart(2, "0");
  const seconds = String(totalSeconds % 60).padStart(2, "0");
  return `${minutes}:${seconds}`;
}

/**
 * Belirli bir kullanıcıya değil, herhangi bir hesaba giriş için kullanılabilen
 * TEK bir evrensel kod üretir (adminConfig/masterCode dokümanı). Mobil tarafta
 * login_phone_code.dart, girilen kodu hem kullanıcının kendi loginCode'una
 * hem de bu master koda karşı kontrol eder (bkz. UserService.watchMasterCode).
 * Belirli bir hesaba bağlı olmadığı için email gönderilmez, sadece Dashboard'da
 * gösterilir — admin bunu destek/test amaçlı manuel iletir.
 *
 * @param {object} db Firestore instance
 * @returns {Promise<{code: string, expiresAt: number}>}
 */
export async function generateMasterCode(db) {
  const code = generateLoginCode();
  const expiresAt = Date.now() + CODE_LIFETIME_MS;
  await setDoc(doc(db, "adminConfig", "masterCode"), { code, expiresAt });
  return { code, expiresAt };
}

/**
 * Halihazırda yazılmış master kodu (varsa) döner. Dashboard açılışında
 * süresi dolmamış bir kod varsa onu tekrar göstermek için kullanılır —
 * her sayfa açılışında gereksiz yere yeni kod üretilip eski kod geçersiz
 * kılınmasın diye.
 *
 * @param {object} db Firestore instance
 * @returns {Promise<{code: string, expiresAt: number} | null>}
 */
export async function getMasterCode(db) {
  const snapshot = await getDoc(doc(db, "adminConfig", "masterCode"));
  return snapshot.exists() ? snapshot.data() : null;
}
