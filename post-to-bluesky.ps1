# post-to-bluesky.ps1
# Posts to your Bluesky feed when you go live.
# URLs and hashtags in your post text are automatically made clickable.
#
# Use a Bluesky App Password — NOT your main account password.
# Generate one at: Bluesky -> Settings -> Privacy and Security -> App Passwords

# ─── CONFIG ──────────────────────────────────────────────────────────────────
$BLUESKY_HANDLE       = "yourhandle.bsky.social"  # e.g. yourname.bsky.social
$BLUESKY_APP_PASSWORD = "xxxx-xxxx-xxxx-xxxx"     # App Password, NOT your login password

# Your stream announcement post text.
# - URLs and #hashtags will automatically be made clickable.
# - Keep it under 300 characters (Bluesky's post limit).
# - Edit this whenever your stream content changes.
$POST_TEXT = "https://twitch.tv/yourchannel Come hang! #YourHashtag"
# ─────────────────────────────────────────────────────────────────────────────

# DO NOT EDIT ANYTHING BELOW THIS LINE

$ErrorActionPreference = "Stop"
$PDS_HOST = "https://bsky.social"
$encoder  = [System.Text.Encoding]::UTF8

# Authenticate
try {
    $authBody = @{ identifier = $BLUESKY_HANDLE; password = $BLUESKY_APP_PASSWORD } | ConvertTo-Json
    $session  = Invoke-RestMethod -Uri "$PDS_HOST/xrpc/com.atproto.server.createSession" `
        -Method POST -ContentType "application/json" -Body $authBody
} catch {
    Write-Host "❌ Auth failed: $_"
    exit 1
}

# Build facets (clickable URLs and hashtags)
# Bluesky requires UTF-8 byte positions, not character positions
$facets = @()

# Find URLs
$urlMatches = [regex]::Matches($POST_TEXT, '(https?://[^\s]+)')
foreach ($match in $urlMatches) {
    $byteStart = $encoder.GetByteCount($POST_TEXT.Substring(0, $match.Index))
    $byteEnd   = $byteStart + $encoder.GetByteCount($match.Value)
    $facets   += @{
        index    = @{ byteStart = $byteStart; byteEnd = $byteEnd }
        features = @(@{ "`$type" = "app.bsky.richtext.facet#link"; uri = $match.Value })
    }
}

# Find hashtags
$tagMatches = [regex]::Matches($POST_TEXT, '#\w+')
foreach ($match in $tagMatches) {
    $byteStart = $encoder.GetByteCount($POST_TEXT.Substring(0, $match.Index))
    $byteEnd   = $byteStart + $encoder.GetByteCount($match.Value)
    $facets   += @{
        index    = @{ byteStart = $byteStart; byteEnd = $byteEnd }
        features = @(@{ "`$type" = "app.bsky.richtext.facet#tag"; tag = $match.Value.Substring(1) })
    }
}

# Build and send the post
try {
    $record = @{
        "`$type"  = "app.bsky.feed.post"
        text      = $POST_TEXT
        createdAt = (Get-Date -Format "o")
        facets    = $facets
    }

    $postBody = @{
        repo       = $session.did
        collection = "app.bsky.feed.post"
        record     = $record
    } | ConvertTo-Json -Depth 10

    $result = Invoke-RestMethod -Uri "$PDS_HOST/xrpc/com.atproto.repo.createRecord" `
        -Method POST -ContentType "application/json" -Body $postBody `
        -Headers @{ Authorization = "Bearer $($session.accessJwt)" }

    Write-Host "✅ Post created successfully!"
    Write-Host "   -> $($result.uri)"
} catch {
    Write-Host "❌ Post failed: $_"
    exit 1
}
