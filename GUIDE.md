# ytcast – step-by-step guide

From a fresh Arch Linux install to YouTube Music playing on your speaker. The names, IP and MAC addresses below are made up; yours will differ.

**You need:**

- Arch Linux with a terminal.
- A Chromecast speaker or amplifier (Chromecast built-in), e.g. a Harman Kardon Citation, Google Nest or Google Home, on the same network as your computer.
- A YouTube account, logged in on [music.youtube.com](https://music.youtube.com) in Firefox.
- Access to your router's admin page (for step 4).

---

## 1. Install

```bash
sudo pacman -S --needed git base-devel
git clone https://github.com/sukkergris/ytcast-tui.git ~/Code/ytcast-tui
cd ~/Code/ytcast-tui
./install.sh
```

`install.sh` builds a package and installs it with pacman, including `fzf`, `yt-dlp` and `python-pychromecast`. Type your password and confirm when pacman asks.

Check that it is installed:

```bash
ytcast help
```

---

## 2. Log in to YouTube Music in Firefox

Open [music.youtube.com](https://music.youtube.com) in Firefox and log in. ytcast reads the login from Firefox when it fetches your liked songs and playlists. It never copies or stores your password.

Using another browser? Put it in the config later (step 5): `cookies=chromium`, `cookies=chrome`, …

---

## 3. Find your speaker

```bash
ytcast scan
```

Example output:

```
192.168.1.23 Kitchen speaker
192.168.1.42 Living room
192.168.1.57 Bedroom display
```

Each line is a speaker's IP address and its name. In this guide the speaker is **Living room** at **192.168.1.42**.

Nothing found? The computer and the speaker must be on the same network (not a guest network), and the speaker must be on.

---

## 4. Give the speaker a fixed IP (recommended)

Your router gives devices their IP address with DHCP, and the address can change when the speaker restarts. ytcast remembers the IP, so if it changes you get `no answer from speaker at 192.168.1.42`. A **DHCP reservation** in the router makes the speaker always get the same IP.

### 4a. Find the speaker's MAC address

The router knows devices by their MAC address. Ask your computer which MAC answers on the speaker's IP:

```bash
ping -c1 192.168.1.42
ip neigh show 192.168.1.42
```

Example output:

```
192.168.1.42 dev wlan0 lladdr a4:77:33:1c:2e:5f REACHABLE
```

The MAC address is the one after `lladdr`: **a4:77:33:1c:2e:5f**.

> **Use this MAC, not the one in the speaker's app.** A speaker often has two network cards, one for cable and one for Wi-Fi, and the app may show the cable one. The router only sees the one the speaker actually uses. `ip neigh` shows exactly that one.

### 4b. Reserve the IP in the router

The menus differ between routers, but the steps are the same:

1. Open the router's admin page in a browser, usually `http://192.168.1.1`, and log in.
2. Find the DHCP settings. Typical names are *LAN → DHCP Server*, *Address Reservation*, *Static leases* or *Manual Assignment*.
3. Turn on manual assignment if there is a switch for it. On ASUS routers: *LAN → DHCP Server → Enable Manual Assignment = Yes*.
4. Add a reservation:

   | Field | Example |
   |---|---|
   | MAC address | `A4:77:33:1C:2E:5F` |
   | IP address | `192.168.1.42` |
   | Name (if asked) | `Living room` |

5. Save or Apply.

Easiest is to reserve the IP the speaker already has, as above. Then nothing changes now, and it stays like that.

### 4c. Restart the speaker

The speaker keeps its old lease until it renews it. Unplug the power, wait about 10 seconds and plug it in again. After a minute or two:

```bash
ytcast scan
```

The speaker should be at the reserved IP.

---

## 5. Choose the speaker in ytcast

```bash
ytcast use 192.168.1.42
```

```
Using Living room at 192.168.1.42 (saved in /home/you/.config/ytcast/config)
```

The choice is saved in `~/.config/ytcast/config`:

```bash
host=192.168.1.42
cookies=firefox
```

---

## 6. Open the UI

Check first that nobody else is using the speaker; ytcast takes it over:

```bash
ytcast status
```

Then open the UI:

```bash
ytcast
```

```
╭─ ytcast 0.9.1 │ Living room │ [ Liked (gl) ]  Playlists (gp)  Search (gs)  Speakers (gS) ─╮
│                                                                                 │
│ ...                                                                             │
├─ Press ? for shortcuts ─────────────────────────────────────────────────────────┤
│ ■                                                                               │
│   vol ▁▂▃········ 30                                                            │
╰─────────────────────────────────────────────────────────────────────────────────╯
```

The first time, it fetches your liked songs, which takes a few seconds ("loading…"). They are saved, so the next start is instant. `r` fetches them again.

Press `?` to show or hide the shortcuts.

---

## 7. Play your liked songs

1. Move with `j` / `k`, or `gg` / `G` for the top / bottom.
2. Press `enter` on a song. It plays, and the list continues from there.

The footer shows what is playing:

```
▶ Midnight Harbour
  The Paper Lanterns – Low Tide
  1:12 ━━━━━━━━━──────────────────── 3:58
  vol ▁▂▃········ 30   41 queued
```

While the song you chose is fetched, its row says `⋯ Midnight Harbour -- Fetching…` (yellow). When it plays, it turns green with ▶. While the next song is fetched, the footer says `⋯ Loading 2/42…`.

The line just above the footer tells you what ytcast is waiting for, with a spinner and the seconds so far:

```
⠹ Fetching your liked songs from YouTube Music… 4s
⠼ Searching albums for "paper lanterns" and looking up their names… 2s
⠧ Starting "Midnight Harbour"…
✓ Queued: Low Tide
```

When nothing is going on, it says `Press ? for shortcuts`.

---

## 8. Playlists

1. `gp` (go to playlists) jumps to the **Playlists** tab. `gt` / `gT` also step through the tabs.
2. `l` or `enter` opens a playlist, e.g. *Sunday Morning*.
3. `enter` on a song plays the playlist from there.
4. `h` goes back to the list of playlists.

---

## 9. Search

1. `gs` (go to search) jumps to the **Search** tab. You can type right away.
2. Type e.g. `paper lanterns` and press `enter`. The results come after a second or two.
3. Move to a song and press `enter` again to play it, followed by the rest of the results.

`tab` switches between **Songs**, **Videos** (live versions, music videos, covers) and **Albums** for the same search. On Albums, `l` or `enter` opens an album, `enter` on a song plays the album from there, and `h` goes back.

`/` starts a new search, and `esc` goes back to moving with `j` / `k`.

On the other tabs `/` filters the list instead: type `harbour` to find *Midnight Harbour* among your liked songs.

---

## 10. Control playback

In the UI:

| Key | Action |
|---|---|
| `gl` · `gp` · `gs` · `gq` · `gS` | go to: liked · playlists · search · queue · speakers |
| `dd` · `dG` | on the Queue tab: remove the song · everything after the one playing |
| `m` | menu for the song: play · play next · add to queue · open · remove |
| `space` | pause / resume |
| `n` · `p` | next · previous song |
| `+` · `-` | volume up · down (5 at a time) |
| `a` | add the song (or a whole playlist / album) to the end of the queue |
| `q` | quit the UI; **the music keeps playing** |

`enter` replaces the queue with the list from that song; `a` adds to it without stopping what plays. The footer shows how many songs are queued.

To see the queue, press `gq` (go to queue):

```
  Until Eternity ‒ Blackbriar                 (grey: played)
▶ I'd Rather Burn ‒ Blackbriar                (green: playing)
  Arms of the Ocean ‒ Blackbriar
  Midnight Harbour ‒ The Paper Lanterns       (added with a)
```

`enter` jumps to a song, `dd` removes it, and `dG` removes everything after the one playing.

Press `m` for a **menu** with the actions for the row under the cursor, shown in place of the list (`j`/`k` and `enter` to choose, `esc` or `h` to go back):

```
  Arms of the Ocean ‒ Blackbriar
  Play from here           enter
  Play next
  Add to queue             a
```

**Play next** puts the song (or a whole playlist / album) right after the one playing. On a playlist or album the menu also has *Open* and *Play all*; on the Queue tab *Jump to this song* and *Remove from queue*.

From any terminal, also with the UI closed:

```bash
ytcast vol 25        # set volume (0–100)
ytcast vol -5        # down 5
ytcast pause         # pause / resume
ytcast next          # next song
ytcast status        # what is playing
ytcast stop          # stop
```

Play something without the UI:

```bash
ytcast play 'https://music.youtube.com/playlist?list=OLAK5uy_example'   # a playlist or song, in quotes
ytcast play the paper lanterns midnight harbour                          # the first search result
```

---

## 11. Use another speaker

In the UI: `gS` to **Speakers**, choose one and press `enter` (the line above the footer reminds you: `enter: use this speaker · r: scan again`). `r` scans the network again, e.g. for a speaker you just turned on. Or from the terminal:

```bash
ytcast scan
ytcast use 192.168.1.23
```

Give that speaker a fixed IP too (step 4).

---

## 12. Update or remove

```bash
~/Code/ytcast-tui/install.sh      # update to the latest version
sudo pacman -R ytcast-tui-git     # remove
rm -rf ~/.config/ytcast ~/.cache/ytcast   # also remove the config and the saved lists
```

---

## Troubleshooting

| You see | Do this |
|---|---|
| `no answer from speaker at 192.168.1.42` | The speaker is off or got a new IP. Run `ytcast scan` and `ytcast use <IP>`, and reserve the IP (step 4). |
| `! ERROR … playlist does not exist` on Liked or Playlists | ytcast could not read your login. Log in on music.youtube.com in Firefox (step 2), then press `r`. |
| `! skipped: …` or `! the speaker could not play …` | YouTube refused that song; ytcast went on to the next. Happens now and then. If it happens often: `sudo pacman -Syu yt-dlp`. |
| `the player did not start` | Read the log it names: `cat $XDG_RUNTIME_DIR/ytcast-192.168.1.42.log`. |
| fzf complains about `--no-input` or `--footer` | Your fzf is too old (needs 0.63+): `sudo pacman -Syu fzf`. |
| The router's reservation does nothing | Check that manual assignment is turned on, that the MAC is the one from `ip neigh` (step 4a), and restart the speaker (step 4c). |
