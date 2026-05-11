$configPath = "$env:USERPROFILE\AppData\Roaming\Battle.net"

# 1. 筛选出文件名不是 "Battle.net.config" 的所有 .config 文件
$configFiles = Get-ChildItem -Path $configPath -Filter "*.config" | Where-Object { $_.Name -ne "Battle.net.config" }

foreach ($file in $configFiles) {
    try {
        # 先临时取消只读，否则无法读取内容进行判断
        $isReadOnly = $file.IsReadOnly
        if ($isReadOnly) {
            Set-ItemProperty -Path $file.FullName -Name IsReadOnly -Value $false
        }

        $rawContent = Get-Content -Path $file.FullName -Raw
        # 尝试解析 JSON
        $json = $rawContent | ConvertFrom-Json -ErrorAction SilentlyContinue

        # 2. 关键过滤逻辑：只有包含 User.Client.Favorites 的才是我们要找的账号配置文件
        if ($null -ne $json.User.Client) {
            Write-Host "检测到账号配置文件: $($file.Name)" -ForegroundColor Cyan
            
            # 注入或覆盖关键配置项
            $json.User.Client | Add-Member -MemberType NoteProperty -Name "HasSeenFirstTimeExperience" -Value "true" -Force
            
            # 转换为 JSON 字符串（指定深度防止结构坍塌）
            $newJson = $json | ConvertTo-Json -Depth 10
            
            # 写回并锁定
            $newJson | Set-Content -Path $file.FullName -Encoding UTF8
            Set-ItemProperty -Path $file.FullName -Name IsReadOnly -Value $true
            
            Write-Host "已成功修复并锁定只读。" -ForegroundColor Green
        } else {
            # 如果不是目标文件，恢复它原始的只读状态（如果有的话）
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
