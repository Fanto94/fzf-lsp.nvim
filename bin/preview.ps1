#!/usr/bin/env pwsh

$segments = $args[0] -Split ':'

# Check if first item is a drive letter and offset accordingly
if (Get-PSDrive -LiteralName $segments[0] -PSProvider FileSystem -ErrorAction SilentlyContinue) {
  $FILE = ($segments[0] + ':' + $segments[1])
  $CENTER = $segments[2]
} else {
  $FILE = $segments[0]
  $CENTER = $segments[1]

  # Expand references to home directory `~`
  $FILE = if ($FILE -eq '~') { $HOME } else { $FILE }
  if ("$FILE" -like '~*') {
    $FILE = $HOME + $FILE.Substring(1)
  }
}

if (-Not $CENTER) {
  $CENTER = '0'
}

try {
  $CENTER = [int]$CENTER
} catch {
  Write-Error "Invalid center: $CENTER"
  exit 1
}

[int]$LINES = 0
try {
  [int]$LINES = if ($env:LINES) { [int]$env:LINES } { 100 }
} catch {
  [int]$LINES = 100
  Write-Error "Invalid lines: $env:LINES"
}

$UP = $CENTER - $LINES / 2
$UP = if ($UP -ge 1) { [int]$UP } else { 1 }
$DOWN = $CENTER + $LINES / 2
$DOWN = if ($DOWN -lt $LINES) { [int]$LINES } else { $UP + ([int]$DOWN) }

if (Get-Command -Name 'bat' -All -ErrorAction SilentlyContinue) {
  $BAT_STYLE = if ($env:BAT_STYLE) { $env:BAT_STYLE } else { 'numbers' }
  bat --style="$BAT_STYLE" --color=always --highlight-line="$CENTER" `
    --line-range="${UP}:${DOWN}" "$FILE"
} else {
  # Shows an arrow `>` on the matching line
  # Caveats, more than one line can match
  $line_highlight = Get-Content -LiteralPath $FILE | Select-Object -Index ($CENTER - 1)
  Get-Content -LiteralPath $FILE | Select-String -SimpleMatch $line_highlight -Context $UP,$DOWN
}

