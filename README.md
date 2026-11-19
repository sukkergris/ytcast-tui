# ytcast-tui

YouTube Music on Chromecast speakers from the terminal, made for a Harman Kardon Citation but works with any Cast device (Nest, Google Home, …). Browse your liked songs, your playlists and search results (songs, videos, albums) with fzf and vim keys, play from any song or add it to the queue, and see "now playing" in the footer.

New to this? Follow the **[step-by-step guide](GUIDE.md)**, from installing to playing, including how to give the speaker a fixed IP in your router.

Unofficial; not affiliated with Google or YouTube. Sibling of [hk-tui](https://github.com/sukkergris/hk-tui) (your own music files) and [bluos-tui](https://github.com/sukkergris/bluos-tui) (BluOS players).

## Install

### Arch Linux

**Prerequisites:** `git` and `base-devel` (for `makepkg`). The other dependencies (`fzf`, `curl`, `iproute2`, `python-pychromecast`, `yt-dlp`) are installed by `makepkg`.

```bash
sudo pacman -S --needed git base-devel
git clone https://github.com/sukkergris/ytcast-tui.git ~/Code/ytcast-tui
cd ~/Code/ytcast-tui
./install.sh         # installs the dependencies, ytcast and ytcast-player to /usr/bin
```

Update: `~/Code/ytcast-tui/install.sh`. It pulls the latest version from GitHub, builds the package and installs it with pacman. Restart the player daemon afterwards, so it runs the new code: `pkill -f ytcast-player` (the next `ytcast` command starts it again; the song playing finishes, but the queue stops until then).
Uninstall: `sudo pacman -R ytcast-tui-git`
Changing the code? See [Development](#development).

### First run

1. Log in on music.youtube.com in Firefox. ytcast reads the login from there (like `yt-dlp --cookies-from-browser firefox`); nothing is copied or stored.
2. Pick a speaker and open the UI:

```bash
ytcast scan               # Cast speakers on the network, e.g. "192.168.1.13 Living room"
ytcast use 192.168.1.13   # pick one (saved in the config)
ytcast                    # opens the UI on your liked songs
```

The first start fetches your liked songs (a few seconds; the label says "loading…"). They are cached, so later starts are instant; press `r` to refresh.

### Troubleshooting

- **"no answer from speaker at <IP>":** the speaker is off, or it got a new IP from DHCP. Run `ytcast scan` and `ytcast use <IP>`, and reserve the IP in your router's DHCP (with the MAC the network sees: `ip neigh show <IP>`).
- **Liked or Playlists shows "! ERROR … playlist does not exist":** yt-dlp could not read your login. Log in on music.youtube.com in Firefox, or set `cookies=` to the browser you use (`chrome`, `chromium`, …).
- **"! skipped: …" or "! the speaker could not play …" in the footer:** YouTube refused that track (removed, region-locked, or the stream URL was refused), so ytcast skipped to the next one. Updating yt-dlp often helps (`sudo pacman -Syu yt-dlp`).
- **"the player did not start":** see the log it names, `$XDG_RUNTIME_DIR/ytcast-<IP>.log`.
- **fzf error about unknown options (`--no-input`, `--footer`):** your fzf is older than 0.63.

## Usage

```bash
ytcast                   # UI
ytcast play URL|QUERY    # a song or playlist URL, or the first search result
ytcast pause             # pause / resume
ytcast next|prev         # next / previous track
ytcast stop              # stop playback
ytcast vol [N|+N|-N]     # show or set volume (0–100)
ytcast status            # what is playing
ytcast scan              # Cast speakers on the local network
ytcast use <IP>          # switch speaker and save it in the config
```

| Key | Action |
|---|---|
| `j` · `k` · `ctrl-d` · `ctrl-u` · `gg` · `G` | move · half page · top / bottom |
| `gt` · `gT` | tabs: liked → playlists → search → speakers |
| `gl` · `gp` · `gs` · `gS` | go to: liked · playlists · search · speakers |
| `tab` | Search tab: songs → videos → albums |
| `l` · `h` | open playlist / album · back |
| `/` · `esc` | filter the list (on the Search tab: type a new search) · back |
| `enter` | play from this song · open playlist / album · run the search · choose speaker |
| `a` | add the song, or all songs of a playlist / album, to the end of the queue |
| `space` · `n` · `p` · `+` · `-` | pause · next · previous · volume |
| `r` | refresh the list |
| `?` · `q` | shortcuts · quit (playback continues) |

On the **Search** tab you type right away; `enter` runs the search, and `enter` again plays the song under the cursor. `tab` switches between songs, videos and albums for the same search, like the chips on music.youtube.com. Artists and playlists can't be searched: yt-dlp doesn't list them.

`enter` replaces the queue with the list from the chosen song; `a` adds to the end of the queue without stopping what plays.

## Config

`~/.config/ytcast/config` (written by `ytcast use` and when you choose a speaker in the UI):

```bash
host=192.168.1.13   # speaker IP
cookies=firefox     # browser to read the YouTube login from; empty = no login (search only)
```

## How it works

- **Two parts:** `ytcast` (bash) is the UI and CLI. `ytcast-player` (Python, pychromecast) is a small daemon per speaker that keeps the Cast connection and the queue. `ytcast` starts it on demand and talks to it with curl over a unix socket (`$XDG_RUNTIME_DIR/ytcast-<IP>.sock`). Playback continues when you quit the UI; the daemon quits after 30 minutes without playback.
- **Streams:** right before a song plays, yt-dlp turns its YouTube URL into an audio stream (m4a), which the speaker fetches from YouTube itself. Stream URLs expire, so they are never resolved far ahead; the next song is resolved in the background while the current one plays.
- **No cover art:** a speaker without a screen (Citation Amp) refuses the whole track when the metadata has a webp thumbnail, so none is sent.
- **Lists:** liked songs (`music.youtube.com/playlist?list=LM`) and your playlists (`youtube.com/feed/playlists`) are fetched with `yt-dlp --flat-playlist` and cached in `~/.cache/ytcast/`. Search uses `music.youtube.com/search?q=…#songs` (`#videos`, `#albums`), max 30 results. Album results come without names, so each album is looked up (in parallel, ~3 s).
- **Status line:** the line just above "now playing" shows what ytcast is waiting for, with a spinner and the seconds so far, e.g. `⠹ Searching YouTube Music for "blackbriar" (albums)… 3s`, and `✓ Queued: …` after `a`. Each slow job (fetching a list, starting a song, adding to the queue) writes its message to `$YT_DIR/busy.<pid>`, and the ticker shows the newest one while that process runs.
- **Speakers:** found by asking every address on the /24 network for `http://<IP>:8008/setup/eureka_info`, which Cast devices answer with their name.

## TODO

### Test Liked and Playlists with the Firefox login (for 0.2)

The development runs had no login (`cookies=`), so only search and playback are tested. About 15 minutes. Write down what you see, and the numbers from step 4.

The daemon logs every track to `$XDG_RUNTIME_DIR/ytcast-<IP>.log`, one line each:

```
2026-11-19 10:01:58 started  192.168.1.42  cookies=firefox
2026-11-19 10:02:03 played   https://music.youtube.com/watch?v=…  Midnight Harbour
2026-11-19 10:06:11 skipped  https://music.youtube.com/watch?v=…  ERROR: [youtube] …: Video unavailable
2026-11-19 10:06:15 refused  https://music.youtube.com/watch?v=…  Low Tide
```

`skipped` = yt-dlp found no stream, `refused` = the speaker could not play the stream (usually HTTP 403 from YouTube). The log starts over each time the daemon starts.

- [ ] **1. Liked (~5 min)**
  - [ ] `ytcast`: how long does "loading…" take the first time?
  - [ ] `enter` on the first song; let the queue play 3–4 songs (`n` to go faster). Does it keep going?
  - [ ] How many shorts or other non-music videos are among the first 50?
- [ ] **2. Playlists (~3 min)**
  - [ ] `gp` → Playlists, `l` opens one, `enter` on a song plays it.
  - [ ] `h` back, open another one. Are the lists right? Non-music playlists in the list?
- [ ] **3. Cache (~1 min)**
  - [ ] `q` and `ytcast` again: Liked shows at once.
  - [ ] `r` fetches the list again ("loading…").
- [ ] **4. Search and queue (new in 0.2, ~5 min)**
  - [ ] Search tab: type a search, `enter`. `tab` → Videos, `tab` → Albums (names after ~3 s), `tab` → Songs.
  - [ ] Albums: `l` opens one, `enter` on a song plays the album from there, `h` back to the albums.
  - [ ] While a song plays: `a` on a song → "+ queued" in the label and one more "queued" in the footer; it plays after the queue.
  - [ ] `a` on an album or playlist adds all its songs.
  - [ ] With nothing playing (`ytcast stop`): `a` starts the song at once.
- [ ] **5. Refused streams, with and without login (~5 min)**
  - [ ] With the login: play 20 songs from Liked (`n` to step quickly), then count and save the log:

    ```bash
    grep -cE ' (skipped|refused) ' $XDG_RUNTIME_DIR/ytcast-*.log   # failed
    grep -c ' played ' $XDG_RUNTIME_DIR/ytcast-*.log                # started
    cp $XDG_RUNTIME_DIR/ytcast-*.log ~/ytcast-with-login.log
    ```

  - [ ] Without the login: stop the daemon so it starts again with the new setting, set `cookies=` (empty) in `~/.config/ytcast/config`, and play the same 20 songs. Liked still shows, because the list is cached.

    ```bash
    ytcast stop; pkill -f ytcast-player
    sed -i 's/^cookies=.*/cookies=/' ~/.config/ytcast/config
    ytcast                                                          # the same 20 songs
    grep -cE ' (skipped|refused) ' $XDG_RUNTIME_DIR/ytcast-*.log
    grep -c ' played ' $XDG_RUNTIME_DIR/ytcast-*.log
    ```

  - [ ] Set the login back: `sed -i 's/^cookies=.*/cookies=firefox/' ~/.config/ytcast/config; pkill -f ytcast-player`
- [ ] **6. Report:** the notes and the two pairs of numbers from step 5. 0.2 is planned from them (e.g. a filter for shorts, and resolving streams with or without login).

## Development

Two scripts install the app. Users only need `install.sh`; `dev.sh` is for trying changes.

| Script | Installs | Use it when |
|---|---|---|
| `./install.sh` | the package built from what is **pushed to GitHub** (`git pull`, `makepkg -sf`, `pacman -U`). pacman owns the files, and `pacman -Q ytcast-tui-git` shows the version. | you use the app, and after you have pushed a change |
| `./dev.sh` | your **working copy**: copies `bin/ytcast` and `bin/ytcast-player` straight to `/usr/bin` with `sudo install`, uncommitted changes included. Needs `sudo pacman -S python-pychromecast yt-dlp` once. | you want to try a change before committing it |

A typical change:

1. Edit `bin/ytcast` and `bin/ytcast-player`.
2. Try it: run `bin/ytcast` from the repo (nothing installed), or `./dev.sh` to have it as `ytcast` everywhere.
3. Commit and push.
4. `./install.sh` puts the packaged version back. It takes over the files `dev.sh` copied (`pacman -U --overwrite`); without that, pacman refuses with "exists in filesystem".

Good to know:

- `makepkg` writes the new `pkgver` (e.g. `r6.cce9dd8`) into `PKGBUILD`. Commit it as `chore: opdater pkgver fra makepkg`.
- After `./dev.sh`, `pacman -Qkk ytcast-tui-git` reports the files as modified. That is expected until the next `./install.sh`.
- Version bump: change `app="ytcast X.Y.Z"` in `bin/ytcast`, commit, add an annotated tag `vX.Y.Z` and push with `git push --follow-tags`.
- **Restart the daemon** after `./dev.sh` or `./install.sh`: `pkill -f ytcast-player`. A running `ytcast-player` keeps the old code until it quits.
- **Test runs talk to the real daemon.** There is one daemon per speaker, found by its socket (`$XDG_RUNTIME_DIR/ytcast-<IP>.sock`), so `bin/ytcast` from the repo controls the same queue as the installed one. Check `ytcast status` before testing, and use another config (`XDG_CONFIG_HOME=/tmp/test-config`) with a speaker nobody listens to.

## License

MIT
