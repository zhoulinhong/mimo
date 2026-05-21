# ============================================================
# 代理重置原因诊断脚本
# 如果修复脚本运行后，重启电脑代理仍然被重置，运行此脚本定位元凶
# ============================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   代理重置原因诊断工具"
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# -----------------------------------------------------------
# 1. 检查组策略
# -----------------------------------------------------------
Write-Host "【1】检查组策略" -ForegroundColor Yellow
$gpoPaths = @(
    "HKLM\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings",
    "HKCU\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings",
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Group Policy Objects"
)
foreach ($path in $gpoPaths) {
    if (Test-Path "registry::$path") {
        Write-Host "  [警告] 存在组策略覆盖: $path" -ForegroundColor Red
        reg query $path 2>$null | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
    } else {
        Write-Host "  [OK] 未发现: $path" -ForegroundColor Green
    }
}

# -----------------------------------------------------------
# 2. 检查计划任务
# -----------------------------------------------------------
Write-Host ""
Write-Host "【2】检查可能重置代理的计划任务" -ForegroundColor Yellow
$tasks = Get-ScheduledTask | Where-Object {
    $_.TaskName -match "proxy|网络|network|VPN|Clash|V2Ray|SSR|加速|dai li|Netch|Proxifier" -or
    $_.Description -match "proxy|网络|network|VPN|Clash|V2Ray"
}
if ($tasks) {
    foreach ($t in $tasks) {
        Write-Host "  [发现] $($t.TaskName) - 状态: $($t.State)" -ForegroundColor Magenta
    }
} else {
    Write-Host "  [OK] 未发现可疑计划任务" -ForegroundColor Green
}

# -----------------------------------------------------------
# 3. 检查启动项
# -----------------------------------------------------------
Write-Host ""
Write-Host "【3】检查所有启动项" -ForegroundColor Yellow
$startupItems = Get-CimInstance Win32_StartupCommand
if ($startupItems) {
    foreach ($item in $startupItems) {
        $cmd = $item.Command
        $isSuspicious = $cmd -match "proxy|VPN|网络加速|Clash|V2Ray|SSR|Shadowsocks|Netch|SSTap|Proxifier|Fiddler|Charles|Burp|网络|代理|dai li|tun|tap"
        if ($isSuspicious) {
            Write-Host "  [可疑] $($item.Name): $cmd" -ForegroundColor Magenta
        } else {
            Write-Host "  [常规] $($item.Name): $cmd" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "  [OK] 无启动项" -ForegroundColor Green
}

# -----------------------------------------------------------
# 4. 检查运行中的可疑进程
# -----------------------------------------------------------
Write-Host ""
Write-Host "【4】检查当前运行的网络相关进程" -ForegroundColor Yellow
$suspiciousProcs = Get-Process | Where-Object {
    $_.ProcessName -match "clash|v2ray|ssr|shadowsocks|netch|sstap|proxifier|fiddler|charles|burp|wireguard|nordvpn|expressvpn|surfshark|protonvpn|openvpn|netch|tun2socks|privoxy|squid|ccproxy|winpac|tap"
}
if ($suspiciousProcs) {
    foreach ($p in $suspiciousProcs) {
        Write-Host "  [发现] $($p.ProcessName) (PID: $($p.Id))" -ForegroundColor Magenta
    }
} else {
    Write-Host "  [OK] 未发现已知代理/VPN 进程" -ForegroundColor Green
}

# -----------------------------------------------------------
# 5. 检查当前代理注册表值
# -----------------------------------------------------------
Write-Host ""
Write-Host "【5】当前代理注册表值" -ForegroundColor Yellow
$is = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction SilentlyContinue
if ($is) {
    Write-Host "  AutoDetect（自动检测）: $($is.AutoDetect)"
    Write-Host "  ProxyEnable（代理开关）: $($is.ProxyEnable)"
    Write-Host "  ProxyServer（代理地址）: $($is.ProxyServer)"
    Write-Host "  ProxyOverride（例外列表）: $($is.ProxyOverride)"
    Write-Host "  AutoConfigURL（自动配置URL）: $($is.AutoConfigURL)"
}

Write-Host ""
Write-Host "【6】WinHTTP 代理" -ForegroundColor Yellow
netsh winhttp show proxy

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  诊断完成。如果上面标注了 [可疑] 或 [发现] 的项，"
Write-Host "  请检查对应软件是否在启动时设置了系统代理。"
Write-Host ""
Write-Host "  常见场景："
Write-Host "  - Clash / V2Ray / SSR 等代理工具设置了'开机启动+系统代理'"
Write-Host "  - 某些 VPN 软件修改了系统代理配置"
Write-Host "  - 抓包工具(Fiddler/Charles)开启了系统代理后未关闭"
Write-Host "  - 公司域策略或 IT 管理软件强制设置代理"
Write-Host "========================================" -ForegroundColor Cyan

pause
