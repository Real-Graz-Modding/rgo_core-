# Mitarbeit an rgo_core

Danke, dass du zu rgo_core beitragen möchtest! 🎉  
Bitte lies diese Richtlinien, bevor du einen Bug meldest, ein Feature vorschlägst oder Code einreichst.

---

## 🐛 Bug gefunden?

1. Prüfe zuerst, ob der Bug bereits unter [Issues](https://github.com/Real-Graz-Modding/rgo_core-/issues) gemeldet wurde.
2. Wenn ein **offenes** Issue deinen Bug beschreibt, ergänze dort weitere Informationen.
3. Wenn kein passendes Issue existiert, erstelle ein neues:
   - Verwende einen **aussagekräftigen Titel** und eine **klare Beschreibung**.
   - Füge **Codebeispiele** oder **Reproduktionsschritte** bei.
   - Nutze die bereitgestellte Bug-Report-Vorlage.

---

## 🔧 Bug gepatcht?

1. Öffne einen neuen Pull Request mit **ausschließlich** den relevanten Änderungen.
2. Beschreibe klar:
   - Was das Problem war
   - Wie deine Lösung funktioniert
   - Welche Issues dadurch behoben werden (z.B. `Fixes #42`)

---

## 💡 Verbesserung oder neues Feature?

1. Erstelle zuerst ein Issue, das die Änderung beschreibt, und warte auf Feedback.
2. Wenn du bereits Code geschrieben hast, kannst du einen **Draft Pull Request** für frühe Überprüfung einreichen.
3. **Nicht alle Features werden akzeptiert.** Änderungen können unvollständig, schlecht geplant oder unvereinbar mit der Designphilosophie sein.

---

## 🎨 Kosmetische Änderungen (z.B. Formatierung)?

Pull Requests, die **keine substanzielle Verbesserung** der Stabilität oder Funktionalität bewirken, werden nicht akzeptiert.

---

## 📬 Pull Requests einreichen

1. Forke das Repository und erstelle einen neuen Branch (z.B. `fix/esx-callback-bug` oder `feat/qbcore-vehicles`).
2. Stelle sicher, dass dein Code dem bestehenden Stil entspricht.
3. Wenn relevant: Füge Beispielcode bei, der deine Änderungen demonstriert.
4. Öffne den Pull Request gegen den `main`-Branch.

---

## 📐 Coding-Richtlinien

- **Lua**: Konsistenter Stil mit bestehenden `server/main.lua`- und `client/main.lua`-Dateien.
- **TypeScript** (rgo_core Kern): `bun run lint` vor dem Einreichen ausführen.
- Keine neuen externen Abhängigkeiten hinzufügen, ohne es vorher im Issue zu diskutieren.
- Keine Ressourcennamen mit dem Präfix `ox_` verwenden – das ist für offizielle [Overextended](https://github.com/overextended)-Ressourcen reserviert.
