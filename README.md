# ytcast-tui

YouTube Music on Chromecast speakers from the terminal, made for a Harman Kardon Citation but works with any Cast device (Nest, Google Home, …). Browse your liked songs, your playlists and search results with fzf and vim keys, play from any song, and see "now playing" in the footer.

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

Update or reinstall: `~/Code/ytcast-tui/install.sh` (runs `git pull` and `makepkg -sif`; it builds what is pushed to GitHub, not local changes)
Development: `./dev.sh` copies the local `bin/ytcast` and `bin/ytcast-player` to `/usr/bin`, uncommitted changes included (needs `sudo pacman -S python-pychromecast yt-dlp` once). Run `./install.sh` to go back to the packaged version.
Uninstall: `sudo pacman -R ytcast-tui-git`

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
| `l` · `h` | open playlist · back |
| `/` · `esc` | filter the list (on the Search tab: type a new search) · back |
| `enter` | play from this song · open playlist · run the search · choose speaker |
| `space` · `n` · `p` · `+` · `-` | pause · next · previous · volume |
| `r` | refresh the list |
| `?` · `q` | shortcuts · quit (playback continues) |

On the **Search** tab you type right away; `enter` runs the search, and `enter` again plays the song under the cursor.

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
- **Lists:** liked songs (`music.youtube.com/playlist?list=LM`) and your playlists (`youtube.com/feed/playlists`) are fetched with `yt-dlp --flat-playlist` and cached in `~/.cache/ytcast/`. Search uses `music.youtube.com/search`.
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
  - [ ] `gt` → Playlists, `l` opens one, `enter` on a song plays it.
  - [ ] `h` back, open another one. Are the lists right? Non-music playlists in the list?
- [ ] **3. Cache (~1 min)**
  - [ ] `q` and `ytcast` again: Liked shows at once.
  - [ ] `r` fetches the list again ("loading…").
- [ ] **4. Refused streams, with and without login (~5 min)**
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
- [ ] **5. Report:** the notes and the two pairs of numbers from step 4. 0.2 is planned from them (e.g. a filter for shorts, and resolving streams with or without login).

## License

MIT
