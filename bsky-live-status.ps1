# bsky-live-status.ps1
# Sets or clears your Bluesky "Go Live" status.
# Called by bsky-set.bat (set) and bsky-clear.bat (clear) — do not run directly.
#
# Use a Bluesky App Password — NOT your main account password.
# Generate one at: Bluesky -> Settings -> Privacy and Security -> App Passwords

# ─── CONFIG ──────────────────────────────────────────────────────────────────
$HANDLE        = "yourhandle.bsky.social"   # e.g. yourname.bsky.social
$PASSWORD      = "xxxx-xxxx-xxxx-xxxx"      # App Password, NOT your login password
$PDS_HOST      = "https://bsky.social"      # Change only if you're on a custom PDS

# Stream info — edit these before saving:
$STREAM_URL    = "https://twitch.tv/yourchannel"  # Your Twitch (or other) stream URL
$STREAM_TITLE  = "Live Now!"                       # Shown as the link card title
$STREAM_DESC   = "Come hang!"                      # Shown as the link card description
$DURATION_MINS = 240                               # Max is 240 (4 hrs) — enforced by Bluesky.
                                                   # A value IS required for the LIVE badge to appear.
# ─────────────────────────────────────────────────────────────────────────────

# DO NOT EDIT ANYTHING BELOW THIS LINE

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("set", "clear")]
    [string]$Mode
)

$ErrorActionPreference = "Stop"

function New-Session {
    $body = @{ identifier = $HANDLE; password = $PASSWORD } | ConvertTo-Json
    try {
        $res = Invoke-RestMethod -Uri "$PDS_HOST/xrpc/com.atproto.server.createSession" `
            -Method POST -ContentType "application/json" -Body $body
        return $res
    } catch {
        Write-Host "❌ Auth failed: $_"
        exit 1
    }
}

function Set-LiveStatus($session) {
    $record = @{
        "`$type"  = "app.bsky.actor.status"
        status    = "app.bsky.actor.status#live"
        createdAt = (Get-Date -Format "o")
        embed     = @{
            "`$type"  = "app.bsky.embed.external"
            external  = @{
                uri         = $STREAM_URL
                title       = $STREAM_TITLE
                description = $STREAM_DESC
            }
        }
        durationMinutes = $DURATION_MINS
    }

    $body = @{
        repo       = $session.did
        collection = "app.bsky.actor.status"
        rkey       = "self"
        record     = $record
    } | ConvertTo-Json -Depth 10

    try {
        Invoke-RestMethod -Uri "$PDS_HOST/xrpc/com.atproto.repo.putRecord" `
            -Method POST -ContentType "application/json" -Body $body `
            -Headers @{ Authorization = "Bearer $($session.accessJwt)" } | Out-Null
        Write-Host "✅ Bluesky status set to LIVE"
        Write-Host "   -> $STREAM_URL"
    } catch {
        Write-Host "❌ Failed to set status: $_"
        exit 1
    }
}

function Clear-LiveStatus($session) {
    $body = @{
        repo       = $session.did
        collection = "app.bsky.actor.status"
        rkey       = "self"
    } | ConvertTo-Json

    try {
        Invoke-RestMethod -Uri "$PDS_HOST/xrpc/com.atproto.repo.deleteRecord" `
            -Method POST -ContentType "application/json" -Body $body `
            -Headers @{ Authorization = "Bearer $($session.accessJwt)" } | Out-Null
        Write-Host "✅ Bluesky live status cleared"
    } catch {
        # RecordNotFound is fine — status was already cleared
        if ($_.Exception.Response.StatusCode -ne 400) {
            Write-Host "❌ Failed to clear status: $_"
            exit 1
        }
        Write-Host "✅ Bluesky live status already cleared"
    }
}

$session = New-Session

if ($Mode -eq "set") {
    Set-LiveStatus $session
} else {
    Clear-LiveStatus $session
}
