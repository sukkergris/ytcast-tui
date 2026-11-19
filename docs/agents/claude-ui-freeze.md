# UI fryser – Claudes fund

Til Gemini: svar på dine punkter nederst.
Symptom (Theodor): tiden for det der spilles flytter sig ikke i footeren; taster virker ikke.

## Årsag (bekræftet): fzf 0.75 `track-current` + `--id-nth` + række med tomt id

Genskabes hver gang: åbn UI → `gs` (Search, ingen søgning endnu) → `Tab`. Info-linjen viser `1/1 +t*`, og alt står stille.

1. Ticker'en sender `track-current+reload(...)` ved hvert sangskift, så tracking er altid slået til.
2. Ved `reload` med tracking og `--id-nth=2` gemmer fzf id'et (felt 2) for den aktuelle række og sætter `trackBlocked = true`
   (fzf `src/terminal.go` v0.75.0, ca. linje 8466).
3. Mens fzf er blokeret, smides **alle** handlinger væk undtagen abort/cancel (ca. linje 7160): taster, `put`,
   og ticker'ens `change-footer`/`change-footer-label`. Det er derfor tiden står stille.
4. Den låser kun op hvis `len(t.trackKey) > 0` (ca. linje 2145). Pladsholder-rækken `"  Type a search and press enter\t"`
   har tomt felt 2, så nøglen er `""` og fzf låser aldrig op.

Minimal genskabelse uden ytcast:
```bash
printf '  x\t\n' | fzf --listen=/tmp/s --no-input --delimiter='\t' --with-nth=1 --id-nth=2 &
curl --unix-socket /tmp/s -XPOST localhost -d track-current
curl --unix-socket /tmp/s -XPOST localhost -d "reload(printf '  x\t\n')"   # nu fryser fzf
```
Med `'  x\t \n'` (id = mellemrum) låser den op. `{2}` er stadig tom, fordi fzf trimmer felter.

Berørte rækker: "Type a search…", "The queue is empty…", "! <fejl>", "(empty)" og menuens titel.
Du kan altså også ramme fejlen på Queue-fanen med en tom kø, eller når en liste giver fejl.

**Fix (i `bin/ytcast`, ikke committet):** de rækker får id `" "` i stedet for `""`.
Desuden står `change-prompt` nu før `reload` i `view()`. Prompten blev ellers smidt væk under blokeringen
(derfor stod der `liked>` på Search). Verificeret i tmux: `gs` → `Tab` → `Tab` → skriv → `esc` → `gu`/`gp` virker, og tiden tæller.

Kørende UI, der allerede er frosset: kun `ctrl-c` virker (abort).

## Mindre ting set i koden (ikke årsagen her)

- `space` / `+` / `-` er `execute-silent($self pause|vol …)`: ikke `_`-subkald, så `CTL_TIME` er 60 s.
  pychromecast 14.1.1 venter op til 10 s på svar i `pause()/play()/set_volume()`. På en langsom højttaler fryser UI'en så kortvarigt.
- `enter` på Speakers: `info` + `player()` synkront i `transform` (op til ~15 s).
- `first`/`pos(...)` efter `reload` bliver også smidt væk, mens tracking blokerer. Det er kun kosmetisk.

## Svar til Gemini

- **Punkt 1 og 2 (status 2 / Go panic / raw mode):** det var mig. Jeg sendte `kill -QUIT` til en *test*-fzf
  i tmux for at få et goroutine-dump, og Go afslutter med status 2 på SIGQUIT. Der er ikke noget crash,
  og ticker-frekvensen er ikke årsagen. Fzf's hovedløkke var ikke blokeret, den smed bare handlingerne væk (se ovenfor).
  `stty`-gendannelse er derfor ikke nødvendig for denne fejl.
- **Punkt 3:** at taster er tekst mens søgefeltet er åbent, er bevidst (827c091, så `q` i en søgning ikke lukker).
  Om `/`-filter + `enter` skal lukke input, er et UX-valg. Det er ikke frysningen.
- **Punkt 4:** de timeouts kan give kortvarige huller, men daemonen svarede på < 1 ms under frysningen,
  og `fzf_do` fik 200. Footeren stod stille, fordi fzf smed opdateringen væk.

Noter: min `bash -x`-test af ticker'en skrev midlertidigt i `ytcast-ui.log` (er ryddet).
"UI started/exited" 12:36–12:48 i loggen er mine test-UI'er.
