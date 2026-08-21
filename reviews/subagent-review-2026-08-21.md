# Subagent-Review v0.4.0 — 2026-08-21

Fünf Subagents, jeder auf einen Blickwinkel: Vertrag Writer↔Reader, Test-Substanz,
Doku-Drift, Component-Qualität (clara), Simplify-Pass. Alle im Report-Modus, nichts geändert.

Alles unter "verifiziert" habe ich in dieser Session selbst nachgeprüft (Befehl + Ausgabe oder
`path:line`). Alles andere ist als Subagent-Behauptung markiert.

**Disposition:** Abschnitt 1 und 2 (die Verlust-Kette und die Carry-Formel) sind in **v0.4.1**
behoben, inklusive des gescopeten Verifier-Checks und der zwei Superseded-Hinweise im Plan.
Abschnitt 3 bis 7 sind offen. Der Text unten ist der Stand vom Review-Tag und wird nicht
nachgezogen.

---

## 0. Ausgangslage (verifiziert)

| Check | Ergebnis |
|---|---|
| `pwsh -File .\tests\validate-commands.ps1` | `Passed: 176  Failed: 0  Total: 176`, Exit 0 |
| `diff -q commands/session-handoff.md ~/.claude/commands/session-handoff.md` | keine Ausgabe (identisch) |
| `diff -q commands/session-resume.md ~/.claude/commands/session-resume.md` | keine Ausgabe (identisch) |

Deploy-Parität hält. Die Suite ist grün. Beides ist wahr und beides sagt weniger, als es aussieht.

---

## 1. P1 — Die Verlust-Kette

Vier Funde, ein Ursprung. Das ist der wichtigste Teil des Reviews.

### 1.1 Zwei Regeln widersprechen sich, und die falsche steht in "Hard rules"

`commands/session-handoff.md:340-341` (Hard rules):

> Der nächste Schritt existiert **genau einmal**, in "→ Pick up here" — der Status-Block hat
> bewusst keine `Next:`-Zeile, **und Open work wiederholt ihn auch nicht**.

`commands/session-handoff.md:111-117` (Schritt 3):

> **Open work darf den nächsten Schritt nicht als Prosa wiederholen — aber das Item selbst muss
> da sein.** […] **Ein Item, das NUR in "→ Pick up here" existiert, ist für den Zähler des
> nächsten Handoffs unsichtbar und geht verloren.**

Die erste Regel verbietet, was die zweite verlangt. Beide Lesarten sind zulässig. Die erste steht
im Abschnitt, den ein Modell auf der Suche nach Zwängen zuerst liest.

### 1.2 Die Verlust-Regel ist beim ersten Handoff einer Kette nie sichtbar

`commands/session-handoff.md:90` begrenzt Schritt 3: `### Step 3 — Carry-forward (only when NN ≥ 02)`.

Darin stehen drei Regeln, die nichts mit Carry-forward zu tun haben:

- `:98` "ein Item pro Bullet"
- `:109` "Schließen ist explizit" (`- Done:`-Bullet)
- `:111-117` die Spotlight-Regel aus 1.1

Keine davon steht ein zweites Mal in "Hard rules" (verifiziert: `grep -n "one item per bullet\|Closing is explicit\|must not restate"` liefert nur 98, 109, 111). Bei `_01` läuft
Schritt 3 nicht. Also wird die Regel, die Item-Verlust verhindert, bei jeder neuen Kette
übersprungen.

### 1.3 Das Referenz-Artefakt des Repos zeigt genau diesen Verlust — und der Test war grün

Datei: `tests/behavioral/format-boundary/.sandbox/proj/.claude/session-handoffs/legacy-chain_02.md`

Das Szenario setzt genau ein neues offenes Item (`format-boundary/scenario.md:21-22`, das laute
Retry-Logging). Im erzeugten Artefakt steht es an zwei Stellen:

- `:8` Status-Satz
- `:12` "→ Pick up here"

`## Open work` (`:14-17`) enthält: zwei `- Done:`-Bullets und `- Carried unchanged: 14 items`.
**Kein `- Open:`-Bullet.** (Selbst gelesen.)

Das ist wörtlich der Fehlerfall aus `:111-117`. Der Agent hat sich dabei an Hard rules gehalten —
siehe 1.1.

Der Check, der das fangen sollte, ist `tests/behavioral/format-boundary/verify.ps1:94`:

```powershell
Check 'noisy retry logging is recorded as open' ($t -match '(?i)(logging|log level|noisy)')
```

`$t` ist die **ganze Datei**. Der Status-Satz erfüllt das Muster. Der Test besteht auf einem
Artefakt, das die zentrale Invariante bricht. (Selbst gelesen.)

`format-boundary` ist laut Test-Prüfer das einzige Szenario, das dem Agent die Antwort *nicht*
vorsagt — und das einzige, das einen echten Defekt produziert hat. Der eigene Verifier hat ihn
durchgelassen.

### 1.4 Der Plan schreibt die zurückgenommene Regel weiter fest

`plan/readability-preflight-plan.md:141-144` und `:989-990` (Subagent-Behauptung, Zeilen nicht
selbst geöffnet):

> "Open work wiederholt den nächsten Schritt nie. […] Open work hält, was *nach* dem nächsten
> Schritt kommt, nie den nächsten Schritt selbst."

Die Status-Zeile des Plans sagt "Track A shipped". Wer aus dem Plan nachimplementiert, baut den
Defekt wieder ein.

**Vorschlag (nicht ausgeführt):** "and Open work never repeats it either" aus `:341` streichen und
durch einen Verweis auf die Spotlight-Regel ersetzen. 1.1, 1.2, 1.3 und 1.4 sind danach erledigt.
Zusätzlich `:98`, `:109`, `:111-117` aus Schritt 3 nach oben ziehen (reines Verschieben, kostet
keine Tokens, und die 5 Checks darauf sind Ganzdatei-Checks, brechen also nicht).

---

## 2. P1 — Die Carry-Formel im Command ist die zurückgenommene Formel

`commands/session-handoff.md:107-108` (selbst gelesen):

> **`N` must add up:** `N` = the previous file's total item count minus what you closed this session.

`docs/decision-log.md:179` und `tests/compat-old-chain.ps1:316` (selbst gelesen):

> `implied_new = carried + closed + written_out_still_open - previous_total`

Der Command-Datei fehlt der Term `written_out_still_open`. Die Korrektur ist in den Scanner, den
Decision-Log und den Changelog gewandert, aber nicht in die Datei, die das Modell ausführt.

Sie widerspricht auch der Zeile drei darüber: `:104-106` definiert `N` als "alles, was nicht neu,
geändert oder geschlossen ist" — das ist `previous_total − closed − written_out_still_open`.
Zwei Formeln, gleiche Bullet-Liste.

Fixture-Gegenprobe (Subagent-Behauptung): `tests/fixtures/carry-ok/demo_03.md` schreibt
`Carried unchanged: 2`, die Command-Formel ergäbe 3. Das goldene "korrekt"-Fixture widerspricht
dem Command-Text.

Der Wächter fängt es nicht: `tests/compat-old-chain.ps1:322-327` schlägt nur bei
`implied_new < 0` fehl. Ein zu hohes `N` läuft still durch und vergiftet den nächsten Hop.
Der statische Check `validate-commands.ps1:167` prüft nur, dass die Zeichenkette
"must add up" existiert — egal welche Formel danach steht.

**Zusätzlich (Subagent-Behauptung):** Die Zähl-Grammatik `:119-138` ist per Überschrift auf
*alt-formatige* Vorgänger begrenzt. Für einen Format-2-Vorgänger gibt es keine Grammatik, und
`- Done:` sowie `- Carried unchanged:` werden nach `:121` ("An item is a top-level `- ` bullet")
als offene Items mitgezählt. Der Scanner schließt beide explizit aus
(`compat-old-chain.ps1:155-163`); ins Command ist nur die Group-Header-Hälfte gewandert.

---

## 3. P2 — `/session-resume` ist auf drei Feldern blind

Alle drei selbst per grep verifiziert.

| Writer schreibt | Reader liest |
|---|---|
| `**Format:** 2` (`session-handoff.md:291`), Hard rule `:342-346` | nie. `grep -in "format:" commands/session-resume.md` → 0 Treffer |
| akzeptiert **beide** Open-work-Überschriften (`:98-100`) | kennt nur `## Open work`. `grep -in "Deferred"` → 0 Treffer |
| `- Done:` als Schließ-Mechanismus (`:109-110`, Template `:305`) | kennt es nicht. `grep -in "Done:"` → 0 Treffer |

Folgen:

- Der Reader schließt das Format aus der Tag-Form (`session-resume.md:89-90`, `:180`). Das ist in
  beide Richtungen falsch: ein Format-2-File darf laut Leiter-Fall (d) `:367-369` einen nackten
  Tag schreiben, und ein Format-1-File darf einen Anker haben (Subagent nennt
  `old-format-resume/.sandbox/.../oldfmt-c_01.md:140` als echtes Beispiel).
- Der einzige Carry-Hop, der im Feld existiert, zeigt auf eine Datei mit der **alten**
  Überschrift. Der Reader hat davon nie gehört.
- Der Reader "faltet die Items" der Hop-Datei ins Briefing (`:109-110`). Auf `carry-ok/demo_02.md`
  sind das ausschließlich `Done:`-Bullets — geschlossene Items werden als offene präsentiert
  (Subagent-Behauptung, Fixture nicht selbst geöffnet).

**Struktureller Fund, kein Wording-Fehler (Subagent-Behauptung):** Der Writer darf nur `{NN-1}`
lesen (`:92`, `:384-385`), der Reader nur einen Hop (`:108`, `:111-112`). Ein Item, das zweimal
unverändert weitergetragen wurde, liegt textlich zwei Dateien zurück. Es kann dann nie mehr
geschlossen werden (`- Done: {item}` braucht den Text) und nie mehr gelesen werden. `:117`
verspricht "so it can be counted **and closed**" — das hält nur einen Hop weit.

---

## 4. P2 — Die Tests messen überwiegend, ob Sätze noch dastehen

Selbst verifiziert: `grep -c 'Contains(' tests/validate-commands.ps1` → **119**.

Der Test-Prüfer klassifiziert (Behauptung, Methodik plausibel): 22 von 176 Checks haben echte
strukturelle Kraft (Existenz, Deploy-Parität, Step-Zählung und -Lückenlosigkeit,
Reihenfolge-Indizes, Fixture-Exitcodes), 154 prüfen Textvorkommen in genau der Datei, die sie
validieren sollen.

Konkrete Beispiele, die nicht fehlschlagen können:

| Zeile | Check heißt | prüft real | Vorkommen im Ziel |
|---|---|---|---|
| `:247` | "resume puts open work after those three" | Wort `Then` | 5 |
| `:209` | "ignores .claude/session-handoffs/" | `.claude/session-handoffs/` | 15 |
| `:290` | "--all includes done/ archive" | `done/` | 5 |
| `:337` | "skips tree check on older handoffs" | `older` | 4 |

Abschnitt G (`:124-135`, Template-Vollständigkeit) prüft ungescoped gegen die ganze Datei. Sechs
der Abschnittsnamen kommen schon in der Schritt-3-Prosa `:93-94` vor. Man kann `## Running state`
aus dem Template löschen, der Check bleibt grün. Der Autor kennt die Lösung schon: `:224-227`
scoped Abschnitt T bewusst auf `$tpl`.

`tests/README.md:41-42` behauptet das Gegenteil:

> "The assertions are mutation-checked: […] changing one byte flips the relevant check to FAIL —
> the harness is not a rubber stamp."

Das ist für ≥26 Checks widerlegt.

**Drei von vier Behavioral-Szenarien sagen dem Agent die Antwort vor** (Behauptung, mit
Zeilenzitaten belegt): `depth-recovery/scenario.md:20-22` verlangt explizit das Auflisten
verworfener Optionen, `load-discipline/scenario.md:15-18` wiederholt Schritt 4 wörtlich,
`scenarios/s3-resume.md:20` verlangt die Alters-Angabe, die `verify-artifacts.ps1:73` dann sucht.
Getestet wird Prompt-Gehorsam, nicht die Wirkung des Command-Textes.

Weitere Test-Funde:

- **Der Wächter ist durch neue Arbeit blendbar** (`compat-old-chain.ps1:321-327`). Verlust wird
  von neu geschriebenen Items maskiert: 5 vorher, 3 getragen, 0 geschlossen, 3 neu → `implied_new = 1`
  → PASS, obwohl 2 Items fehlen. Real fügt fast jede Session Items hinzu.
- **Behavioral-Zählung falsch** (selbst verifiziert): `README.md:175` und
  `tests/behavioral/README.md:24` sagen "26 checks". `verify-artifacts.ps1` hat 24 Aufrufstellen,
  eine davon in einer 8er-Schleife (`:43`) plus ein if/else-Paar → **30**. Live-Lauf des
  Subagents: `Passed: 4  Failed: 26  Total: 30`.
- **Gate G1 hat keine `scenario.md`** und kann aus dem Repo nicht neu gefahren werden; der
  Vier-Zeilen-Ausgabevertrag, den `old-format-resume/verify.ps1:59-70` verlangt, ist nirgends
  eingecheckt. (Behauptung.)
- **Der S1/S2/S3-Hauptlauf ist nicht reproduzierbar:** `tests/behavioral/README.md:31-32` nennt
  einen Schritt "backdate+snapshot", den kein Skript im Repo umsetzt; `pre-s3-hashes` wird nur
  gelesen (`verify-artifacts.ps1:75`), nie geschrieben. (Behauptung.)
- **Beide `.ps1` deklarieren `#requires -Version 5`, laufen aber nur unter `pwsh` 7.** UTF-8 ohne
  BOM, 5.1 dekodiert als ANSI und bricht am Parser. (Behauptung mit Fehlerausgabe belegt.)
- **`.sandbox/`-Reste enthalten echte private Handoffs** (u.a. eine Kopie von
  `apex-roadtrip` seq 176). Korrekt gitignored (`.gitignore:8`, `tests/behavioral/.gitignore:1`,
  `git ls-files` zeigt sie nicht) — aber relevant, wenn der Ordner je gezippt oder kopiert wird.
  (Behauptung, Ignore-Status vom Subagent per `git status --ignored` belegt.)

**Was echt Zähne hat:** Deploy-Parität (`:81-82`), Step-Zählung (`:95-96`, `:288-289`),
Template-Reihenfolge (`:236-242`) und Abschnitt S (`:262-273`) — der einzige Negativtest im Repo,
und er funktioniert (`carry-ok` → Exit 0, `carry-bad` → Exit 1 mit korrekter Fehlermeldung, vom
Subagent live gefahren).

---

## 5. P2 — Doku-Drift

Selbst verifiziert:

| Fund | Stelle |
|---|---|
| `CLAUDE.md:36-38` sagt "zwei Design-Dokumente", `git ls-files plan` zeigt **drei** | `readability-preflight-plan.md` fehlt, obwohl es das Design-Protokoll des aktuellen Release ist |
| Statische Zählung veraltet in zwei Plänen | `plan/session-handoff-plan.md:179` "85 checks", `plan/token-optimization-plan.md:4` und `:170` "99/99" — echt sind 176 |
| Behavioral-Zählung 26 statt 30 | `README.md:175`, `tests/behavioral/README.md:24` |

`docs/decision-log.md:125-127` hält fest, dass hartkodierte Test-Zahlen genau deshalb durch
Verweise ersetzt wurden, "so they can't go stale in a third place". Der dritte Ort hat überlebt.

Subagent-Behauptungen (Zeilen nicht selbst geöffnet):

- **`plan/session-handoff-plan.md:45-49`** beschreibt zwei Resume-Verhalten, die bewusst umgedreht
  wurden ("working tree dirty" als Staleness-Trigger; "full-load anything that looks like a plan").
  `README.md:205` schickt Leser genau dorthin als "full decision log".
- **1E (`Format:`-Feld) steht noch unter "Deferred, nicht entschieden"** in
  `plan/readability-preflight-plan.md:586-587`, ist aber ausgeliefert.
- **Der A/B-Vergleich, den der Plan zum Merge-Gate macht** (`:608-609`, `:761-764`), ist nirgends
  als gelaufen oder verworfen dokumentiert; das Deliverable `tests/ab/measure-run.ps1` existiert
  nicht. Track A ist trotzdem gemergt und released.
- **`docs/how-it-works.html`** listet 8 statt 9 Handoff-Schritte (`--done` fehlt), nennt "zwei
  Test-Schichten" statt drei, zeigt auf `plan/session-handoff-plan.md` als Decision-Log statt auf
  `docs/decision-log.md`, und hat keinen Versionsstempel.
- **`README.md:108-110`** beschreibt das Vor-v0.2.0-Verhalten ("liest jede verlinkte Plan-Datei"),
  `:115-118` korrigiert es fünf Zeilen später.
- **Ketten-Größe steht als 175 *und* 176** über vier Dokumente verteilt; `docs/decision-log.md:195-200`
  erklärt die Ursache, aber kein Dokument sagt, welche Zahl es meint.

---

## 6. P3 — Component-Qualität (clara)

| Command | Score |
|---|---|
| `/session-handoff` | 57/60 (A) |
| `/session-resume` | 49/60 (B) |

Nach eigener Prüfung gegen die offizielle Doku:

- **`disable-model-invocation: true` fehlt in beiden Dateien.** Das Feld existiert
  (`code.claude.com/docs/en/slash-commands`, Frontmatter-Tabelle: "Set to `true` to prevent Claude
  from automatically loading this skill. Use for workflows you want to trigger manually with
  `/name`.") und die Doku nennt genau diesen Anwendungsfall: "Use this for workflows with side
  effects […] You don't want Claude deciding to deploy because your code looks ready." Die
  "never unasked"-Regel steht derzeit nur als Prosa in `description` und Body. Das ist der
  billigste harte Fix im ganzen Review.
- **`Grep` steht in `session-resume.md:85`, aber nicht in `allowed-tools` (`:4-9`).** Selbst
  verifiziert. **Aber:** clara hat das als "Critical / Runtime-Fehler" eingestuft, und das ist
  falsch. Die Doku sagt zu `allowed-tools`: "It does not restrict which tools are available: every
  tool remains callable, and your permission settings still govern tools that are not listed."
  Es ist eine Vorab-Erlaubnis, keine Sperre. Der fehlende Eintrag bricht nichts, er löst eine
  Nachfrage aus. Runter auf MINOR.
- Windows-Hinweise stehen im Resume erst 80 Zeilen nach den Schritten, die sie betreffen
  (`:157-161` gegen `:62-77`) — im Handoff stehen sie inline bei Schritt 1. Inkonsistenz zwischen
  den beiden Dateien, nicht Teil von Decision 18.
- `HARD STOP` (`:34-38`) zählt vier Ausnahmen auf und übersieht dabei den
  `/revise-claude-md`-Vorschlag aus 7a (`:190-193`), der ebenfalls ein "next step" ist.

Keine Treffer bei: Emojis, unsichtbares Unicode, hartkodierte absolute Pfade, monolithische
Struktur, weiche Entscheidungssprache, fehlende Fehlerbehandlung.

---

## 7. Simplify-Pass (`/simplify`-Blickwinkel, nichts angewandt)

Ehrliches Ergebnis: **die Prompt-Dateien sind schon dicht.** Zusammen 24.558 + 11.447 Bytes,
also rund 9.000 Tokens pro Aufruf-Paar. Verteidigbare Einsparung ohne Risiko: **250–300 Tokens,
etwa 3 %.** Das ist kein Hebel.

Sichere Prosa-Kürzungen (Subagent-Vorschläge, Einsparung geschätzt):

| Fund | Stelle | ~Tokens |
|---|---|---|
| 7b und 7c wiederholen zwei Sätze fast wörtlich; `:167` kann sie tragen | `:200-203`, `:215-218` | 58 |
| Zwei Maintainer-Begründungen im Resume, die nichts anweisen | `session-resume.md:93-95`, `:99-101` | 83 |
| "kein git log"-Regel steht zweimal vollständig | `:44-45` und `:384-385` | 28 |
| Confirm-Block-Parenthese wiederholt ihren eigenen Code-Block | `:276-280` | 50 |

Der größte Einzelposten wäre das Verschieben der beiden `## Customizing`-Abschnitte
(`session-handoff.md:391-398`, `session-resume.md:165-171`, zusammen ~223 Tokens) nach `docs/`.
Das kollidiert mit der `CLAUDE.md`-Vorgabe "self-contained für jeden, der die Dateien ohne dieses
Repo bekommt", und mit einer geplanten Track-B-Änderung an genau dieser Liste. **Produkt-
Entscheidung, kein Cleanup.**

Echte Skript-Funde (alle SAFE, Subagent-Behauptungen mit Zeilen):

- `tests/compat-old-chain.ps1:21` dokumentiert im Kopf noch die zurückgenommene Formel aus
  Abschnitt 2, während `:316-327` das Erhaltungsgesetz implementiert.
- `:15` behauptet "nested bullets never counted on their own", der Code zählt
  Group-Header-Kinder aber mit (`:151-153`, `:181`).
- `:165` `$bullets = $units` — toter Zuweisung, wird nie gelesen.
- Der Multi-Topic-Slug-Fix von 2026-08-21 traf nur eine von drei Meldungen; `:330` und `:334`
  drucken weiter eine nackte Sequenz.
- `validate-commands.ps1:247` ist der Check, der das Wort "Then" prüft (siehe Abschnitt 4).

### Nicht anfassen

Diese Passagen sehen redundant aus und müssen bleiben. Jede hat eine Quelle.

1. **Invocation policy doppelt** (Frontmatter + Body) — `docs/decision-log.md:70-74`, zwei
   Zielgruppen: Harness und Leser.
2. **Die Plattform-Doppelverzweigung** — `docs/decision-log.md:50-58`, `CLAUDE.md` sagt
   ausdrücklich "Do not collapse it into one branch".
3. **Die ganze Zähl-Grammatik `:119-138`, besonders "A bullet wraps"** —
   `docs/decision-log.md:184-194`, der Wrap-Bug versteckte kettenweit rund 900 Items. 11 Checks
   hängen daran.
4. **"Accept either" bei den zwei Überschriften** `:98-100` — `docs/decision-log.md:160-164`,
   alle Bestandsdateien nutzen die alte.
5. **Die fünf G1-Klarstellungen im Resume** (`:73-75`, `:102-107`, `:122-126`, `:138-147`) —
   `docs/decision-log.md:257-268`, alle fünf kamen aus echten Läufen, keine aus dem Lesen.
6. **"do not compress those away"** `:128-132` — Umkehrung würde den 2026-06-30-Fix zurücknehmen.
7. **Die READ-AT-RESUME-Leiter an ihrem Platz** `:347-373` — eine Verschiebung greift einer noch
   offenen Track-B-Entscheidung vor (`plan/readability-preflight-plan.md:774-791`).
8. **Die duplizierte Assertion-Basis in beiden `.ps1`** — `CLAUDE.md` verlangt "no dependencies",
   und `compat-old-chain.ps1` muss standalone gegen fremde Projekte laufen.
9. **Die Abschnitts-Buchstaben in `validate-commands.ps1`** (physisch A–G, R, H, T, S, I–Q) —
   `docs/decision-log.md` zitiert sie als stabile IDs.

---

## 8. Korrekturen an Subagent-Aussagen

- **clara: `Grep`-Lücke = "Critical, Runtime-Fehler."** Falsch. `allowed-tools` ist Vorab-Erlaubnis,
  keine Sperre (offizielle Doku, wörtlich zitiert in Abschnitt 6). MINOR.
- **Ein Subagent nennt `README.md:56-58` als Fundstelle des Erhaltungsgesetzes.** Mein
  `grep -n "implied_new\|conservation\|previous_total\|written_out" README.md` liefert dort keinen
  Treffer. Die Formel steht verifiziert in `docs/decision-log.md:179` und
  `tests/compat-old-chain.ps1:316`. Das README formuliert es vermutlich anders — nicht geprüft.
- **Test-Prüfer: "154 von 176 sind Textvorkommen."** Meine eigene Zählung ist
  `grep -c 'Contains(' tests/validate-commands.ps1` → 119 Stellen. Die 154 kommen aus expandierten
  Schleifen und sind plausibel, aber nicht von mir nachgerechnet.

---

## 9. Nicht verifiziert

- Alle Fixture-Rechnungen in Abschnitt 2 (`carry-ok/demo_*.md`) — Dateien nicht selbst geöffnet.
- Alle Plan-Zeilen in Abschnitt 5 außer den drei selbst geprüften Zahlen.
- Der 5.1-Parse-Fehler der `.ps1`-Skripte — vom Subagent mit Fehlerausgabe belegt, von mir nicht
  reproduziert.
- Die Behauptung, `docs/how-it-works.html` habe keinen Versionsstempel.
- Ob die `format-boundary`-Sandbox der letzte echte Lauf ist oder ein eingefrorenes Fixture.
</content>
