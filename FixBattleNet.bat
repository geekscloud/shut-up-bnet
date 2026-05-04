@echo off
:: 设置字符集为UTF-8，防止中文乱码
chcp 65001 >nul
title 战网图标固定修复工具

echo ==========================================
echo       战网 (Battle.net) 顶部图标强力固定脚本
echo ==========================================
echo.
echo 正在扫描并修复配置文件...

:: 调用 PowerShell 执行核心逻辑，Bypass 绕过执行策略限制
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"$path = \"$env:USERPROFILE\AppData\Roaming\Battle.net\"; " ^
"$files = Get-ChildItem -Path $path -Filter '*.config' | Where-Object { $_.Name -ne 'Battle.net.config' }; " ^
"foreach ($f in $files) { " ^
"  $isRO = $f.IsReadOnly; if ($isRO) { Set-ItemProperty $f.FullName -Name IsReadOnly -Value $false }; " ^
"  $json = Get-Content $f.FullName -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue; " ^
"  if ($null -ne $json.User.Client.Favorites) { " ^
"    $json.User.Client | Add-Member -MemberType NoteProperty -Name 'HasSeenFirstTimeExperience' -Value 'true' -Force; " ^
"    $newJson = $json | ConvertTo-Json -Depth 10; " ^
"    $newJson | Set-Content $f.FullName -Encoding UTF8; " ^
"    Set-ItemProperty $f.FullName -Name IsReadOnly -Value $true; " ^
"    Write-Host '  [成功] 已注入配置并锁定只读: ' -NoNewline; Write-Host $f.Name -ForegroundColor Green; " ^
"  } else { " ^
"    if ($isRO) { Set-ItemProperty $f.FullName -Name IsReadOnly -Value $true } " ^
"  } " ^
"}"

echo.
echo ==========================================
echo 修复完成！请关闭并重新启动战网客户端。
echo ==========================================
pause
