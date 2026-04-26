param([string]$File)
$content = Get-Content $File -Raw
$vars = @{}
# Extract variables
[regex]::Matches($content, 'set\s+"?([^="\s]+)=([^"&\r\n]*)"?') | ForEach-Object {
    $vars[$_.Groups[1].Value] = $_.Groups[2].Value
}
# Resolve !var:~start,length! substring ops
function Resolve-CmdString($str, $vars) {
    # Replace simple !var!
    foreach ($k in $vars.Keys) {
        $str = $str -replace "!$([regex]::Escape($k))!", $vars[$k]
    }
    # Resolve !var:~start,length!
    $str = [regex]::Replace($str, '!([^!:]+):~(-?\d+),(-?\d+)!', {
        param($m)
        $val = $vars[$m.Groups[1].Value]
        if (-not $val) { return $m.Value }
        $start = [int]$m.Groups[2].Value
        $len   = [int]$m.Groups[3].Value
        if ($start -lt 0) { $start = $val.Length + $start }
        if ($len -lt 0)   { $len = $val.Length + $len - $start }
        $val.Substring($start, [Math]::Min($len, $val.Length - $start))
    })
    return $str
}
Write-Host "`n=== Variables ===" -ForegroundColor Cyan
$vars.GetEnumerator() | Sort-Object Name | ForEach-Object {
    Write-Host "$($_.Key) = $($_.Value)"
}
Write-Host "`n=== Deobfuscated Script ===" -ForegroundColor Cyan
$content -split "`n" | ForEach-Object {
    Write-Host (Resolve-CmdString $_ $vars)
}
