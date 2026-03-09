# Bluesky Auto Live Status for Streamers

Automatically set your Bluesky profile to **LIVE** when you start streaming, and clear it when you're done — using Mix It Up and OBS.

No coding experience needed, and **nothing to install**. PowerShell is already built into Windows 10 and 11.

---

## What This Does

When you go live, a script fires that sets your Bluesky profile badge to LIVE with a link to your stream. When you end your stream, another script clears the badge automatically. An optional companion script can also post to your Bluesky feed announcing that you're live.

---

## What You'll Need

- Windows 10 or 11 *(PowerShell is already installed — nothing to download)*
- [Mix It Up](https://mixitupapp.com/) — free streaming bot software
- [OBS](https://obsproject.com/) or Streamlabs OBS
- A [Bluesky](https://bsky.app) account

---

## Step 1 — Get a Bluesky App Password

You'll use an **App Password** instead of your real Bluesky password. This keeps your account safe — if it's ever accidentally exposed, you just delete it and make a new one without changing your login.

1. Log into Bluesky
2. Go to **Settings → Privacy and Security → App Passwords**
3. Click **Add App Password**, give it a name like `stream-bot`
4. Copy the password it gives you — it looks like `xxxx-xxxx-xxxx-xxxx`

---

## Step 2 — Set Up the Files

You'll need four files, all in the same folder (somewhere stable, like `C:\Users\YourName\streaming\bluesky\`):

- `bsky-live-status.ps1` — sets and clears your LIVE status
- `bsky-set.bat` — fires when your stream starts
- `bsky-clear.bat` — fires when your stream ends
- `post-to-bluesky.ps1` *(optional)* — posts to your feed when you go live

### bsky-live-status.ps1

Open the file and fill in the **CONFIG section** at the top:

```powershell
$HANDLE        = "yourhandle.bsky.social"   # Your Bluesky handle
$PASSWORD      = "xxxx-xxxx-xxxx-xxxx"      # Your App Password from Step 1
$STREAM_URL    = "https://twitch.tv/yourchannel"
$STREAM_TITLE  = "Live Now!"
$STREAM_DESC   = "Come hang!"
$DURATION_MINS = 240                        # Leave this as 240 (the maximum Bluesky allows)
```

**Do not change anything below the config section.**

### bsky-set.bat and bsky-clear.bat

Open each `.bat` file and update the script path to wherever you saved `bsky-live-status.ps1`:

```bat
powershell.exe -ExecutionPolicy Bypass -File "C:\Users\YourName\streaming\bluesky\bsky-live-status.ps1" -Mode set
```

The `-ExecutionPolicy Bypass` part is required — Windows restricts PowerShell scripts by default. This flag allows the script to run without changing any system settings.

---

## Step 3 — Test the Scripts

Before wiring anything up to Mix It Up, test that everything works:

1. Open your scripts folder in File Explorer
2. Double-click `bsky-set.bat`
3. A command prompt window will open, run, and show a success message
4. Check your Bluesky profile — the LIVE badge should appear (you may need to refresh)
5. Double-click `bsky-clear.bat` to remove the badge when done

If the window flashes and closes too fast to read, open `bsky-set.bat` in Notepad and add `pause` as a new last line. That'll keep the window open so you can see any error messages.

---

## Step 4 — Wire Up to Mix It Up

1. Open **Mix It Up** and connect it to your streaming account if you haven't already
2. In the left sidebar, go to **Events**
3. Find the **Streaming** category
4. Click **Stream Started**:
   - Add an action → **External Programs** (or "Run Program")
   - Set the **Program** field to: `powershell.exe`
   - Set the **Arguments** field to: `-ExecutionPolicy Bypass -File "C:\Users\YourName\streaming\bluesky\bsky-live-status.ps1" -Mode set`
   - Alternatively, point the Program field directly at `bsky-set.bat` with no arguments
5. Repeat for **Stream Stopped**, using `-Mode clear` or `bsky-clear.bat`

Mix It Up has a **test button (▶)** next to each event — use it to verify everything fires correctly before going live for real.

---

## Also Included — Auto Post on Stream Start *(optional)*

`post-to-bluesky.ps1` posts to your Bluesky feed when you go live, with your stream URL and hashtags automatically made clickable.

### Setup

Open the file and fill in the CONFIG section at the top:

```powershell
$BLUESKY_HANDLE       = "yourhandle.bsky.social"
$BLUESKY_APP_PASSWORD = "xxxx-xxxx-xxxx-xxxx"
$POST_TEXT            = "https://twitch.tv/yourchannel Come hang! #YourHashtag"
```

- URLs and `#hashtags` in `POST_TEXT` are automatically made clickable — no extra work needed
- Keep your post under **300 characters** (Bluesky's limit)
- Update `POST_TEXT` whenever your stream content or tags change

### Wiring Up in Mix It Up

Add it to your **Stream Started** event as a second action alongside the live status script:

- **Program:** `powershell.exe`
- **Arguments:** `-ExecutionPolicy Bypass -File "C:\Users\YourName\streaming\bluesky\post-to-bluesky.ps1"`

Both actions will fire together when you go live.

---

## Troubleshooting

**The badge never shows up**
Make sure `$DURATION_MINS` is set to a number (`240`) in the config. Bluesky requires a duration value to display the LIVE badge — leaving it blank will authenticate and write the record correctly, but the badge won't appear.

**Auth failed error**
Double-check your handle and App Password in the config section. Make sure you're using an App Password, not your regular login password.

**The window flashes and closes immediately**
Add `pause` as the last line of your `.bat` file to keep the window open and read the error message.

**"running scripts is disabled on this system" error**
The `-ExecutionPolicy Bypass` flag in the bat file should prevent this. If you're seeing it, make sure the flag is present and spelled correctly in your bat file.

---

## Notes

- Bluesky enforces a maximum status duration of **4 hours (240 minutes)** regardless of what you set. The `clear` script on stream end is what actually removes the badge in real time — the duration is just a safety fallback.
- Each streamer needs their own copy of the `.ps1` files with their own credentials and stream URL.
- If your App Password is ever accidentally shared or exposed, revoke it immediately in Bluesky settings and generate a new one. Your main account password is never at risk.

---

*Built using the [AT Protocol](https://atproto.com/) and [Bluesky lexicons](https://github.com/bluesky-social/atproto/tree/main/lexicons/app/bsky/actor).*
