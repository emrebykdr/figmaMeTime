// randevular.js'teki "Kullanıcı" arama kutusu (isim/telefonla filtrelenebilen
// öneri listesi) ile aynı davranışı genelleştirir; şube seçimi gibi başka
// alanlarda da (uzmanlar.js, hizmetler.js, randevular.js -> Şube) tekrar
// kullanılabilsin diye buraya taşındı.
//
// Beklenen HTML iskeleti (randevular.html'deki #user-combobox ile aynı):
//   <div class="combobox" id="...">
//     <input type="text" id="...-search" autocomplete="off" />
//     <input type="hidden" id="..." />
//     <div class="combobox-options" id="...-options" hidden></div>
//   </div>
export function attachCombobox({ containerEl, searchEl, hiddenEl, optionsEl, getItems, getLabel, getId }) {
  function renderOptions(filterText) {
    const text = filterText.trim().toLowerCase();
    const items = getItems();
    const matches = text ? items.filter((item) => getLabel(item).toLowerCase().includes(text)) : items;
    const limited = matches.slice(0, 8);

    optionsEl.innerHTML = "";
    if (limited.length === 0) {
      optionsEl.innerHTML = `<div class="combobox-empty">Sonuç yok.</div>`;
    } else {
      limited.forEach((item) => {
        const el = document.createElement("div");
        el.className = "combobox-option";
        el.textContent = getLabel(item);
        el.addEventListener("click", () => selectItem(item));
        optionsEl.appendChild(el);
      });
    }
    optionsEl.hidden = false;
  }

  function selectItem(item) {
    hiddenEl.value = getId(item);
    searchEl.value = getLabel(item);
    optionsEl.hidden = true;
  }

  // Düzenleme formunu doldururken (startEdit) mevcut seçimi, tıklama
  // olmadan doğrudan set etmek için kullanılır. id, mevcut öğe listesinde
  // bulunamazsa (ör. referans verilen kayıt silinmiş/taşınmışsa) hem arama
  // kutusu hem de gizli değer boşaltılır — aksi halde arama kutusu boş
  // görünürken gizli input'ta geçersiz bir id sessizce kalır ve form
  // fark edilmeden o geçersiz id ile kaydedilebilir.
  function setValue(id) {
    const item = getItems().find((i) => getId(i) === id);
    hiddenEl.value = item ? id : "";
    searchEl.value = item ? getLabel(item) : "";
  }

  function clear() {
    hiddenEl.value = "";
    searchEl.value = "";
  }

  searchEl.addEventListener("input", () => {
    hiddenEl.value = "";
    renderOptions(searchEl.value);
  });
  searchEl.addEventListener("focus", () => renderOptions(searchEl.value));
  document.addEventListener("click", (e) => {
    if (!containerEl.contains(e.target)) optionsEl.hidden = true;
  });

  return { setValue, clear };
}
