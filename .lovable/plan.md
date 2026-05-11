
Dette er en stor omgang. Jeg foreslår vi deler det i to leverancer så vi kan se det landet ordentligt undervejs. Sig til hvis du vil have alt på én gang i stedet.

## Leverance 1 — Sprog, design, AI-opsummering, detaljepanel, redigering

**Dansk overalt**
- Sidebar, headers, tomme tilstande, knapper, datoer (`date-fns/locale/da`), tooltips, toasts.
- Edge function system-prompt på dansk så titel + resume kommer på dansk.

**Premium cream design (light som default, dark som warm black)**
- `src/styles.css`: nyt token-sæt
  - light: `--background #F5F0E8`, `--surface #EDE8DC`, `--card` med frosted/blur, varm skygge `--shadow-warm: 0 1px 2px rgba(60,40,20,.04), 0 8px 24px -12px rgba(60,40,20,.12)`
  - dark: `--background #1A1814`, `--surface #221F1A`, varme neutraler
  - accent: dyb varm amber (`oklch(0.72 0.14 70)`) — passer til cream uden at virke AI-generisk
- Inter via `@import` i index.html (allerede sans).
- Frosted card util: `backdrop-blur-xl bg-card/70 border border-border/60 shadow-warm`.
- Spring-animationer via `framer-motion` på kort, panel, modal, complete-tjek.
- Tema-toggle i sidebar (gem i localStorage, default = light/cream).

**Smart AI titel + resume + transskript**
- DB: tilføj `transcript text` og `summary text` kolonner til `tasks`.
- Edge function `capture-task` opdateret: prompt'en beder Gemini returnere
  - `title` = kort emne (3-6 ord)
  - `summary` = 1-2 sætningers resume af hvad brugeren sagde
  - `transcript` = ordret transskription
  - Plus eksisterende felter.
- **Smart dedup/opdatering**: før insert, hent åbne tasks fra sidste 14 dage for `user_id`, send dem til Gemini i en anden tool `update_or_create` der returnerer enten `{action: "update", task_id, patch}` eller `{action: "create", ...}`. Match baseret på titel/kontekst, opdater stille uden bekræftelse.

**Task-kort: titel + resume, udfoldeligt**
- Default: titel + 1 linje resume.
- Click → glider ind fra højre (Sheet/motion) med fuld transskript, alle felter redigerbare (title, priority, due_date via date-time picker, category, status), slet, marker færdig med spring-animation.
- Inline edit på selve kortet for hurtig prioritet/dato (popover).

**Today / Upcoming / All / Completed**
- Today bliver stor og luftig.
- Tilføj `/all` rute med søgning + filtre (priority, category).
- Upcoming bliver 7-dages kalender-style liste.

## Leverance 2 — Kalender to-way, drag & drop, notifikationer, onboarding

- Kalender-view: opgaver med `due_date` vises som blokke; drag mellem dage opdaterer `due_date` (dnd-kit). Auto-indsættelse sker allerede når `due_date` sættes.
- Drag-and-drop reordering inden for dag/prioritet.
- Browser push (Notification API) + reminder-felt på task (`reminder_minutes`), service worker tjekker hvert minut.
- Daglig morgenbriefing kl. 8 (in-app toast + notifikation).
- 3-trins onboarding (første login): download desktop-app (.dmg link, placeholder), opret første opgave, færdig.

---

## Tekniske noter (for fuldstændighed)

- Migration tilføjer `transcript`, `summary`, `reminder_minutes` til `tasks` + `onboarding_completed bool` til ny `user_settings` tabel.
- `framer-motion` og `@dnd-kit/core` + `@dnd-kit/sortable` installeres.
- Dato-format: `dd. MMM HH:mm` med `locale: da`.
- Detaljepanel = shadcn `Sheet` (allerede tilgængelig) med motion-wrap.
- AI-modellen forbliver `google/gemini-2.5-flash` via Lovable AI Gateway.

Skal jeg gå i gang med **Leverance 1** nu? Eller vil du have alt i én omgang?
