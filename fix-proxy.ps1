# ============================================================
# Windows 代理设置修复脚本
# 目标：开启"自动检测设置"，关闭"代理服务器"，并在重启后保持
# 请以管理员身份运行此脚本
# ============================================================

$Host.UI.RawUI.WindowTitle = "代理设置修复工具"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Windows 代理设置修复工具"
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "[错误] 请以管理员身份运行此脚本！" -ForegroundColor Red
    Write-Host "右键此脚本 -> 使用 PowerShell 运行（管理员）" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "[*] 开始诊断代理设置问题..." -ForegroundColor Yellow
Write-Host ""

# -----------------------------------------------------------
# 第一步：备份当前设置
# -----------------------------------------------------------
Write-Host "[1/5] 备份当前注册表设置..." -ForegroundColor Green
$backupPath = "$env:TEMP\proxy-backup-$((Get-Date -Format 'yyyyMMdd-HHmmss')).reg"
reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" $backupPath 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "      已备份到: $backupPath" -ForegroundColor Gray
}

# -----------------------------------------------------------
# 第二步：清除组策略代理限制（最常见的原因）
# -----------------------------------------------------------
Write-Host "[2/5] 清除可能覆盖代理设置的组策略..." -ForegroundColor Green

$gpoPaths = @(
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Group Policy Objects",
    "HKCU\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings",
    "HKLM\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings",
    "HKLM\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ProxySettingsPerUser"
)

foreach ($path in $gpoPaths) {
    $exists = Test-Path "registry::$path"
    if ($exists) {
        Write-Host "      发现策略项: $path，正在删除..." -ForegroundColor Magenta
        Remove-Item -Path "registry::$path" -Recurse -Force -ErrorAction SilentlyContinue
        if ($?) {
            Write-Host "      已删除: $path" -ForegroundColor Gray
        }
    }
}

# 清除可能导致问题的 Connections 子键中的遗留设置
$connPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Connections"
if (Test-Path $connPath) {
    Remove-ItemProperty -Path $connPath -Name "DefaultConnectionSettings" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $connPath -Name "SavedLegacySettings" -ErrorAction SilentlyContinue
    Write-Host "      已清除 Connections 子键中的旧连接配置文件" -ForegroundColor Gray
}

# -----------------------------------------------------------
# 第三步：设置正确的代理值
# -----------------------------------------------------------
Write-Host "[3/5] 应用正确的代理设置..." -ForegroundColor Green

$internetSettings = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"

# 自动检测设置 = 开启
Set-ItemProperty -Path $internetSettings -Name "AutoDetect" -Value 1 -Type DWord
Write-Host "      AutoDetect（自动检测设置）设为 1（开启）" -ForegroundColor Gray

# 代理服务器 = 关闭
Set-ItemProperty -Path $internetSettings -Name "ProxyEnable" -Value 0 -Type DWord
Write-Host "      ProxyEnable（代理服务器）设为 0（关闭）" -ForegroundColor Gray

# 清空代理服务器地址
Set-ItemProperty -Path $internetSettings -Name "ProxyServer" -Value "" -Type String -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $internetSettings -Name "ProxyServer" -ErrorAction SilentlyContinue

# 清空代理例外列表
Set-ItemProperty -Path $internetSettings -Name "ProxyOverride" -Value "" -Type String -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $internetSettings -Name "ProxyOverride" -ErrorAction SilentlyContinue

# 禁用"为所有协议使用相同代理"的标志
Set-ItemProperty -Path $internetSettings -Name "MigrateProxy" -Value 0 -Type DWord

# 删除旧的二进制配置，让 Windows 重新生成
Remove-ItemProperty -Path $internetSettings -Name "DefaultConnectionSettings" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $internetSettings -Name "SavedLegacySettings" -ErrorAction SilentlyContinue

Write-Host "      注册表设置已更新" -ForegroundColor Gray

# -----------------------------------------------------------
# 第四步：设置 WinHTTP 代理为直连
# -----------------------------------------------------------
Write-Host "[4/5] 设置系统级 WinHTTP 代理为直连..." -ForegroundColor Green

netsh winhttp reset proxy 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "      WinHTTP 代理已重置为直连" -ForegroundColor Gray
} else {
    Write-Host "      WinHTTP 代理重置（可能本来就是直连）" -ForegroundColor Gray
}

# -----------------------------------------------------------
# 第五步：创建启动任务确保持久化
# -----------------------------------------------------------
Write-Host "[5/5] 创建开机自启动任务确保持久化..." -ForegroundColor Green

$taskName = "FixProxySettings"
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($existingTask) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "      已删除旧的计划任务" -ForegroundColor Gray
}

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument @"
-NoProfile -WindowStyle Hidden -Command "
`$path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings';
Set-ItemProperty -Path `$path -Name AutoDetect -Value 1 -Type DWord -Force;
Set-ItemProperty -Path `$path -Name ProxyEnable -Value 0 -Type DWord -Force;
netsh winhttp reset proxy > `$null 2>&1;
exit 0"
"@

$trigger = New-ScheduledTaskTrigger -AtLogOn
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "确保代理设置在每次登录时保持正确" -Force | Out-Null

Write-Host "      已创建登录时自动执行的修复任务: $taskName" -ForegroundColor Gray

# -----------------------------------------------------------
# 第六步：检查可疑的第三方软件
# -----------------------------------------------------------
Write-Host ""
Write-Host "[额外] 检查可能重置代理的启动项..." -ForegroundColor Cyan

$suspiciousStartup = Get-CimInstance Win32_StartupCommand | Where-Object {
    $_.Command -match "proxy|VPN|加速|网络|dai li|Clash|V2Ray|SSR|Shadowsocks|Netch|SSTap|Netch|Proxifier|Fiddler|Charles|Burp"
}

if ($suspiciousStartup) {
    Write-Host "      [注意] 发现以下可能影响代理设置的启动项：" -ForegroundColor Yellow
    foreach ($item in $suspiciousStartup) {
        Write-Host "        - $($item.Name): $($item.Command)" -ForegroundColor Yellow
    }
    Write-Host "      建议在对应软件中检查是否勾选了'开机自动设置代理'等选项" -ForegroundColor Yellow
} else {
    Write-Host "      未发现明显的可疑启动项" -ForegroundColor Gray
}

# -----------------------------------------------------------
# 检查 iphlpsvc 服务
# -----------------------------------------------------------
$iphlp = Get-Service -Name "iphlpsvc" -ErrorAction SilentlyContinue
if ($iphlp) {
    Write-Host "      IP Helper 服务状态: $($iphlp.Status), 启动类型: $($iphlp.StartType)" -ForegroundColor Gray
    Write-Host "      (IP Helper 通常不需要干预，但不排除某些场景下会触发代理重置)" -ForegroundColor Gray
}

# -----------------------------------------------------------
# 完成
# -----------------------------------------------------------
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   修复完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  已完成的操作："
Write-Host "  1. 清除了可能覆盖设置的组策略"
Write-Host "  2. 设置 自动检测设置 = 开启"
Write-Host "  3. 设置 代理服务器 = 关闭"
Write-Host "  4. 重置 WinHTTP 代理为直连"
Write-Host "  5. 创建了开机自动纠正的计划任务"
Write-Host ""
Write-Host "  建议：重启电脑后，进入 设置 -> 网络和 Internet -> 代理"
Write-Host "  验证设置是否正确保持。如果问题仍然存在，请运行诊断脚本。"
Write-Host ""

pause
