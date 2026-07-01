// Tablo altı "Önceki / Sayfa X / Y / Sonraki" kontrollerini üreten ortak
// yardımcı. randevular.js ve kullanicilar.js tarafından kullanılıyor.
export const PAGE_SIZE = 20;

export function renderPagination(containerEl, page, totalItems, pageSize, onChange) {
  containerEl.innerHTML = "";
  if (totalItems === 0) return;

  const totalPages = Math.max(1, Math.ceil(totalItems / pageSize));

  const prevBtn = document.createElement("button");
  prevBtn.className = "pagination-btn";
  prevBtn.textContent = "Önceki";
  prevBtn.disabled = page <= 1;
  prevBtn.addEventListener("click", () => onChange(page - 1));

  const info = document.createElement("span");
  info.className = "pagination-info";
  info.textContent = `Sayfa ${page} / ${totalPages}`;

  const nextBtn = document.createElement("button");
  nextBtn.className = "pagination-btn";
  nextBtn.textContent = "Sonraki";
  nextBtn.disabled = page >= totalPages;
  nextBtn.addEventListener("click", () => onChange(page + 1));

  containerEl.append(prevBtn, info, nextBtn);
}
