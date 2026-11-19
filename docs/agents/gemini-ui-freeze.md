# UI fryser & crasher – Geminis fund (til Claude & Theodor)

Dato: 2026-11-19  
Relateret fil: `docs/agents/claude-ui-freeze.md`

---

## 1. Hvorfor shell'en "fryser" efter fzf dør (Terminal RAW mode)

Når fzf starter, sætter det terminalen i raw mode (`-echo -icanon -isig`):
- `-echo`: Tastetryk vises ikke i terminalen.
- `-icanon`: Kanonisk linjebuffer er slået fra.
- `-isig`: `Ctrl-C` (SIGINT) og `Ctrl-\` (SIGQUIT) genererer **ikke** signaler til processen.

Når fzf dør unormalt (f.eks. på Go panic / status 2), når fzf ikke at genskabe termios. Brugeren ryger tilbage til sin zsh-prompt, men shell'en fremstår **totalt bundfrossen** (intet ekko, ingen respons, `Ctrl-C` virker ikke).

### Løsning i `bin/ytcast`:
Gem terminalens tilstand ved opstart og gendan den altid i traps:
```bash
saved_stty=$(stty -g 2>/dev/null || true)
restore_tty() { [[ -n ${saved_stty:-} ]] && stty "$saved_stty" 2>/dev/null || stty sane 2>/dev/null || true; }
trap 'e=$?; restore_tty; echo "$(date +%T) UI exited (status $e)" >>"$uilog"; kill $! 2>/dev/null; rm -rf "$YT_DIR"' EXIT
trap 'restore_tty; exit 129' HUP
trap 'restore_tty; exit 130' INT
trap 'restore_tty; exit 143' TERM
```
*(Midlertidig redning i en frossen shell: tast `Ctrl-J` efterfulgt af `stty sane` i blinde).*

---

## 2. Det fangede crash: Go-runtime panic / exit status 2 i fzf

I tmux-testen døde fzf-panelet direkte med exit status 2:
```text
runtime.gopark(...)
runtime/proc.go:474 +0xca
Pane is dead (status 2, Thu Nov 19 12:38:23 2026)
```
I `uilog`: `12:38:23 UI exited (status 2)`.

### Årsag:
`_ticker` i `bin/ytcast` kører med `sleep 0.12` (~8.3 Hz) for at rotere ASCII-spinneren via `curl` mod `fzf.sock` (`change-footer-label:$msg`).
Selv når der **ikke** er nogen aktiv baggrundsopgave (`!busy`), hamres fzf-socketten konstant med proces-forks og IPC.
Under høj signal-/IPC-aktivitet på `--listen` har fzf en kendt sårbarhed (signal interruption / exit 2 under socket wait).

### Løsning:
* Når intet er `busy`: Tik kun **1 gang i sekundet** (`sleep 1`).
* Når en opgave er `busy`: Tik med `sleep 0.25` eller `sleep 0.4` (rigeligt til en rolig spinner, og reducerer IPC-lasten med 3–4x).

---

## 3. Modal input-lås: Hvorfor tasterne "dør" i Search og ved filtrering (`/`)

I `view()` og commit `827c091`:
```bash
keys='j,k,g,G,h,l,t,T,r,a,s,S,d,m,u,space,n,p,+,-,q,/,?'
```
1. **Search-fælden:**
   Når brugeren skifter til Search (`gs` eller bladrer med `gt`), kaldes `typing_on`. Alle taster i `$keys` unbindes.
   * `q` lukker ikke programmet (taster bogstavet `q`).
   * `gt` og `gT` kan ikke bladre videre til Queue/Speakers (`g` og `t` er slået fra).
   * `j`/`k` kan ikke bevæge sig.
   * Man er låst, medmindre man trykker `Esc`.
2. **Efter sangvalg ved `/`-filter:**
   I `bin/ytcast` under `_enter` (`liked | pl | search | queue`):
   Der returneres `echo "transform-footer($self _now)"` uden `$(typing_off)`.
   Hvis man filtrerede med `/` og trykkede `Enter` på en sang, forblev man **permanent** i `typing`-tilstand med samtlige genveje deaktiveret!
   * Løsning: Kald altid `$(typing_off)` ved `Enter` på en sang.

---

## 4. Hvorfor tiden i footeren stopper med at tælle

Supplerende til Claudes fund om synkrone blokeringer i `space`/`vol`:
1. `_ticker` har `CTL_TIME=2 ctl now || np=""`. Hvis daemonen bruger >2 sekunder (f.eks. pga. et synkront `mc.play_media()` eller `cast.set_volume()` der venter på svar), timer `curl` ud, `np` bliver tom, og daemon-loggen får `BrokenPipeError: [Errno 32] Broken pipe` når den endelig svarer.
2. I `fzf_do` er `--max-time 1` sat: hvis fzf er blokeret i et synkront `execute-silent`, timer `fzf_do` ud og opdateringen afvises.
