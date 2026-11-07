$ErrorActionPreference='Stop'
function Assert($v,$why){if(-not $v){throw $why}}
$tap=[IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'wifi_setup_next18.tap'));$bin=[IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'wifi_setup_next18.bin'))
$blocks=[Collections.Generic.List[byte[]]]::new();$p=0
while($p -lt $tap.Length){Assert ($p+2 -le $tap.Length) 'Truncated TAP';$len=[BitConverter]::ToUInt16($tap,$p);$p+=2;Assert ($len -ge 2 -and $p+$len -le $tap.Length) 'TAP block length';[byte[]]$part=$tap[$p..($p+$len-1)];$xor=0;foreach($b in $part){$xor=$xor-bxor $b};Assert ($xor -eq 0) 'TAP checksum';$blocks.Add($part);$p+=$len}
Assert ($blocks.Count -eq 4 -and $blocks[0][1] -eq 0 -and $blocks[2][1] -eq 3) 'BASIC/CODE blocks'
Assert ($tap.Length -eq 16396 -and $bin.Length -eq 16316) 'Unexpected release lengths'
Assert ([BitConverter]::ToUInt16($blocks[2],14) -eq 49152 -and [BitConverter]::ToUInt16($blocks[2],12) -eq $bin.Length) 'CODE header'
Assert ($blocks[3].Length -eq $bin.Length+2) 'CODE payload length';for($i=0;$i -lt $bin.Length;$i++){Assert ($blocks[3][$i+1] -eq $bin[$i]) 'CODE bytes'}
$loader=[Text.Encoding]::ASCII.GetString($blocks[1]);Assert ($loader.Contains('27647') -and $loader.Contains('49152')) 'Loader CLEAR/USR'
$sy=@{};Get-Content (Join-Path $PSScriptRoot 'wifi_setup_next.sym')|ForEach-Object{if($_ -match '^v0\.([^:]+): EQU 0x([0-9A-Fa-f]+)'){$sy[$matches[1]]=[Convert]::ToInt32($matches[2],16)}}
Assert ($sy['start_address'] -eq 49152 -and $sy['total_len'] -eq $bin.Length -and 49152+$bin.Length -le 65536-64) 'Current C000 layout/boot stack'
Assert ($sy['terminal_start'] -eq 30000 -and $sy['terminal_len'] -eq 5314 -and $sy['AP_list_start'] -eq 35314) 'Terminal/AP memory map'
foreach($n in @('next_init','next_rtc_write','get_baud','return_speed','restore_ix','restore_iy','restore_alt_hl')){Assert ($sy[$n] -ge 49152 -and $sy[$n] -lt 49152+$bin.Length) ('Backend outside payload: '+$n)}
foreach($pair in @(@('bios_start','WifiBios21_NX.cod'),@('terminal_code','terminal11_next_setup.bin'))){$bytes=[IO.File]::ReadAllBytes((Join-Path $PSScriptRoot $pair[1]));$offset=$sy[$pair[0]]-49152;for($i=0;$i -lt $bytes.Length;$i++){Assert ($bin[$offset+$i] -eq $bytes[$i]) ('Embedded component differs: '+$pair[1])}}
$titleStart=$sy['title']-49152;$title=[Text.Encoding]::ASCII.GetString($bin,$titleStart,$sy['title_len']);Assert ($title.Contains('1.8 ZX Next') -and $title.Contains('11/2026') -and $sy['title_len'] -le 64 -and $sy['title_col'] -eq [Math]::Floor((64-$sy['title_len'])/2)) 'Next title/centering'
foreach($name in @('wifi_setup_next18.tap','wifi_setup_next18.bin')){Assert ((Get-FileHash -LiteralPath (Join-Path $PSScriptRoot $name)).Hash -eq (Get-FileHash -LiteralPath (Join-Path $PSScriptRoot ('runable\'+$name))).Hash) 'Runable copy differs'}
'PASS: TAP checksums/payload/loader, memory map, title, embedded BIOS/terminal, output copies.'
