# Lab1_Monitoring_991589924.ps1

$LogName = "Application"
$Src     = "Lab1_Monitoring_991589924"
if (-not [System.Diagnostics.EventLog]::SourceExists($Src)) {
    New-EventLog -LogName $LogName -Source $Src
}
$MyId = "Majd Abboud - 991589924"  

if (-not (Test-Path "C:\Logs")) { New-Item "C:\Logs" -ItemType Directory -Force | Out-Null }

$cores = [Environment]::ProcessorCount

while ($true) {

    $ts  = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $log = "C:\Logs\Lab1_{0}.log" -f (Get-Date -Format 'yyyy-MM-dd')

    $samples = @()
    for ($i=0; $i -lt 30; $i++) {
        $samples += (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
        Start-Sleep -Seconds 1
    }
    $avg30 = (($samples | Measure-Object -Average).Average)
    if ($avg30 -gt 80) {
        $msg = "Part 2: CPU >80% for 30s — please take action (close heavy apps, check Task Manager)."
        Write-Host $msg
        Write-EventLog -LogName $LogName -Source $Src -EntryType Warning -EventId 2 -Message "$ts - $msg"
        Add-Content $log "$ts - $msg"
    }

    $os = Get-CimInstance Win32_OperatingSystem
    $memUsed = (1 - ($os.FreePhysicalMemory / $os.TotalVisibleMemorySize)) * 100
    if ($memUsed -gt 85) {
        $msg = "Part 2: WARNING — memory >85% ($memUsed %)"
        Write-Host $msg
        Write-EventLog -LogName $LogName -Source $Src -EntryType Warning -EventId 3 -Message "$ts - $msg"
        Add-Content $log "$ts - $msg"
    }

    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $freePct = ($disk.FreeSpace / $disk.Size) * 100
    if ($freePct -lt 15) {
        $msg = "Part 2: CRITICAL — C: free <15% ($freePct %)"
        Write-Host $msg
        Write-EventLog -LogName $LogName -Source $Src -EntryType Error -EventId 4 -Message "$ts - $msg"
        Add-Content $log "$ts - $msg"
    }

    $t0    = Get-Date
    $start = Get-Process | Select-Object Id,Name,CPU
    Start-Sleep -Seconds 30
    $end    = Get-Process | Select-Object Id,Name,CPU
    $window = ((Get-Date) - $t0).TotalSeconds

    foreach ($p in $end) {
        $before = ($start | Where-Object Id -eq $p.Id).CPU
        if ($before -ne $null) {
            $delta   = $p.CPU - $before
            $percent = ($delta / $window / $cores) * 100
            if ($percent -gt 80) {
                $msg = "Part 3: terminating $($p.Name) (PID $($p.Id)) — >80% for ~1 minute"
                Write-Host $msg
                Stop-Process -Id $p.Id -Force
                Write-EventLog -LogName $LogName -Source $Src -EntryType Warning -EventId 5 -Message "$ts - $msg"
                Add-Content $log "$ts - $msg"
            }
        }
    }

    if ($freePct -lt 15) {
        $beforeFree = $disk.FreeSpace
        Remove-Item "C:\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
        $freedMB = ($disk.FreeSpace - $beforeFree) / 1MB
        $msg = "Part 3: deleted C:\Temp, freed about $freedMB MB; C: now $((($disk.FreeSpace/$disk.Size)*100)) % free"
        Write-Host $msg
        Write-EventLog -LogName $LogName -Source $Src -EntryType Information -EventId 6 -Message "$ts - $msg"
        Add-Content $log "$ts - $msg"
    }

    if ($memUsed -gt 85) {
        $msg = "Part 3: memory high — investigate running programs/services (>$memUsed %)"
        Write-Host $msg
        Write-EventLog -LogName $LogName -Source $Src -EntryType Warning -EventId 7 -Message "$ts - $msg"
        Add-Content $log "$ts - $msg"
    }

    $now   = Get-Date
    $since = $now.AddMinutes(-1)

    $ev4625 = Get-WinEvent -FilterHashtable @{LogName='Security';Id=4625;StartTime=$since} -ErrorAction SilentlyContinue
    $users  = foreach($e in $ev4625){ [xml]$x=$e.ToXml(); ($x.Event.EventData.Data | Where-Object { $_.Name -eq 'TargetUserName' }).'#text' }
    $users  = $users | Where-Object { $_ }
    $groups = $users | Group-Object | Where-Object Count -ge 2
    foreach($g in $groups){
        $msg = "Part 4: [SECURITY ALERT] Multiple failed login attempts detected for user: $($g.Name) , identified by $MyId on $ts"
        Write-Host $msg
        Write-EventLog -LogName $LogName -Source $Src -EntryType Warning -EventId 4625 -Message "$ts - $msg"
        Add-Content $log "$ts - $msg"
    }

    $ev4740 = Get-WinEvent -FilterHashtable @{LogName='Security';Id=4740;StartTime=$since} -ErrorAction SilentlyContinue
    foreach($e in $ev4740){
        [xml]$x=$e.ToXml()
        $u = ($x.Event.EventData.Data | Where-Object { $_.Name -eq 'TargetUserName' }).'#text'
        if($u){
            $msg = "Part 4: [SECURITY ALERT] Account lockout detected for user: $u , identified by $MyId on $ts"
            Write-Host $msg
            Write-EventLog -LogName $LogName -Source $Src -EntryType Error -EventId 4740 -Message "$ts - $msg"
            Add-Content $log "$ts - $msg"
        }
    }

    $svc = Get-WinEvent -FilterHashtable @{LogName='System';Id=@(7031,7034);StartTime=$since} -ErrorAction SilentlyContinue
    foreach($e in $svc){
        $name = $null
        if($e.Properties.Count -gt 0){ $name = $e.Properties[0].Value }
        if(-not $name){ $name = $e.ProviderName }
        $msg = "Part 4: [SECURITY ALERT] Unexpected service stop: $name , identified by $MyId on $ts"
        Write-Host $msg
        Write-EventLog -LogName $LogName -Source $Src -EntryType Error -EventId $e.Id -Message "$ts - $msg"
        Add-Content $log "$ts - $msg"
    }
}

