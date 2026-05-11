@echo off
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { $c = Get-Content -Raw '%~f0'; $pattern = '(?s)<#PSScript#>(.*?)<#EndPSScript#>'; $scriptContent = [regex]::Match($c, $pattern).Groups[1].Value; $sb = [ScriptBlock]::Create($scriptContent); & $sb }"
exit /b
<#PSScript#>
$configPath = "$env:USERPROFILE\AppData\Roaming\Battle.net"

# 筛选出文件名不是 Battle.net.config 的 .config 文件
$configFiles = Get-ChildItem -Path $configPath -Filter "*.config" | Where-Object { $_.Name -ne "Battle.net.config" }

foreach ($file in $configFiles) {
    try {
        $isReadOnly = $file.IsReadOnly
        if ($isReadOnly) {
            Set-ItemProperty -Path $file.FullName -Name IsReadOnly -Value $false
        }

        $rawContent = Get-Content -Path $file.FullName -Raw
        $json = $rawContent | ConvertFrom-Json -ErrorAction SilentlyContinue

        # 只处理包含 User.Client 节点的账号配置文件
        if ($null -ne $json.User.Client) {
            Write-Host "检测到账号配置文件: $($file.Name)" -ForegroundColor Cyan
            
            $json.User.Client | Add-Member -MemberType NoteProperty -Name "HasSeenFirstTimeExperience" -Value "true" -Force
            
            $newJson = $json | ConvertTo-Json -Depth 10
            
            $newJson | Set-Content -Path $file.FullName -Encoding UTF8
            Set-ItemProperty -Path $file.FullName -Name IsReadOnly -Value $true
            
            Write-Host "已成功修复并锁定只读。" -ForegroundColor Green
        } else {
            if ($isReadOnly) {
                Set-ItemProperty -Path $file.FullName -Name IsReadOnly -Value $true
            }
            Write-Host "跳过非账号配置文件: $($file.Name)" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "解析 $($file.Name) 出错，已跳过。" -ForegroundColor Yellow
    }
}

Write-Host "`n操作完成！" -ForegroundColor Magenta
<#EndPSScript#>
