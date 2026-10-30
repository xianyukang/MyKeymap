<#
.SYNOPSIS
    MyKeymap 无人值守验证总入口。

.DESCRIPTION
    顺序执行并汇总四道关卡, 任何一道失败都计入总失败数:

      1) go build ./...         (config-server)
      2) go test  ./...         (config-server)
      3) AHK 编译校验           (bin\AutoHotkey64.exe /ErrorStdOut /validate)
      4) 行为断言 harness       (tools\test\harness\lib_test.ahk, T1..T17)

    末尾固定输出一行机器可读汇总:
        VERIFY RESULT: PASS (n/n)
        VERIFY RESULT: FAIL (k/n)
    并以退出码反映结果(0 = PASS, 1 = FAIL, 2 = 环境不可用)。

    无人值守保证:
      - 全部子进程重定向输出并异步读流(避免管道填满造成的假死);
      - 每个子进程都有硬超时, 超时即 Kill(含子进程树), 绝不挂死;
      - harness 自身另有 OnExit + 看门狗, 双重保险;
      - 不依赖任何交互输入。

.PARAMETER SkipGo
    跳过 go build/go test(只想跑 AHK 部分时用, 便于本地快速迭代)。

.PARAMETER HarnessTimeoutSec
    行为 harness 的超时秒数, 默认 180。

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File tools\run_verify.ps1
#>
[CmdletBinding()]
param(
    [switch]$SkipGo,
    [int]$HarnessTimeoutSec = 180
)

$ErrorActionPreference = 'Continue'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$ahkExe   = Join-Path $repoRoot 'bin\AutoHotkey64.exe'
$harness  = Join-Path $repoRoot 'tools\test\harness\lib_test.ahk'
$csDir    = Join-Path $repoRoot 'config-server'

# ── 结果收集 ──────────────────────────────────────────────────────────────
$results = [System.Collections.Generic.List[object]]::new()
$failCount = 0
$total = 0

function Add-Result {
    param([string]$Name, [bool]$Ok, [string]$Detail = '')
    $script:total += 1
    if (-not $Ok) { $script:failCount += 1 }
    $status = if ($Ok) { 'PASS' } else { 'FAIL' }
    $script:results.Add([pscustomobject]@{ Name = $Name; Status = $status; Detail = $Detail })
    $suffix = if ($Detail) { " — $Detail" } else { '' }
    Write-Host ("[{0}] {1}{2}" -f $status, $Name, $suffix)
}

<#
  统一的子进程执行器。
  - 异步读取 stdout/stderr, 避免大量输出把匿名管道填满导致子进程阻塞;
  - 超时后 Kill($true) 杀掉整棵进程树, 不留残余 AHK 进程。
  返回: @{ ExitCode; StdOut; StdErr; TimedOut }
#>
function Invoke-Child {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string]$Arguments,
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [int]$TimeoutSec = 300
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName               = $FilePath
    $psi.Arguments              = $Arguments
    $psi.WorkingDirectory       = $WorkingDirectory
    $psi.UseShellExecute        = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.CreateNoWindow         = $true
    # 让 .NET / Go 输出都用 UTF-8, 避免中文乱码
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $psi.StandardErrorEncoding  = [System.Text.Encoding]::UTF8

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi

    try {
        $null = $proc.Start()
    } catch {
        return @{ ExitCode = -1; StdOut = ''; StdErr = ("start failed: " + $_.Exception.Message); TimedOut = $false }
    }

    $outTask = $proc.StandardOutput.ReadToEndAsync()
    $errTask = $proc.StandardError.ReadToEndAsync()

    $finished = $proc.WaitForExit($TimeoutSec * 1000)
    $timedOut = $false
    if (-not $finished) {
        $timedOut = $true
        try { $proc.Kill($true) } catch { try { $proc.Kill() } catch {} }
        try { $null = $proc.WaitForExit(5000) } catch {}
    }

    $stdout = ''
    $stderr = ''
    try { $stdout = $outTask.GetAwaiter().GetResult() } catch {}
    try { $stderr = $errTask.GetAwaiter().GetResult() } catch {}

    $code = if ($finished) { $proc.ExitCode } else { -2 }
    try { $proc.Dispose() } catch {}

    return @{ ExitCode = $code; StdOut = $stdout; StdErr = $stderr; TimedOut = $timedOut }
}

function Write-ChildOutput {
    param($Res, [int]$MaxLines = 40)
    if ($Res.StdOut -and $Res.StdOut.Trim()) {
        $lines = $Res.StdOut.TrimEnd() -split "`r?`n"
        if ($lines.Count -gt $MaxLines) {
            Write-Host ("    ... (" + ($lines.Count - $MaxLines) + " lines omitted)")
            $lines = $lines[($lines.Count - $MaxLines)..($lines.Count - 1)]
        }
        foreach ($l in $lines) { Write-Host ("    " + $l) }
    }
    if ($Res.StdErr -and $Res.StdErr.Trim()) {
        foreach ($l in ($Res.StdErr.TrimEnd() -split "`r?`n")) { Write-Host ("    [err] " + $l) }
    }
}

Write-Host '=========================================================='
Write-Host ' MyKeymap 无人值守验证'
Write-Host (" repo: " + $repoRoot)
Write-Host (" time: " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Write-Host '=========================================================='

# ── 0. 环境前置 ───────────────────────────────────────────────────────────
if (-not (Test-Path $ahkExe)) {
    Write-Host ("[FATAL] AutoHotkey 解释器不存在: " + $ahkExe)
    Write-Host 'VERIFY RESULT: FAIL (0/0)'
    exit 2
}
if (-not (Test-Path $harness)) {
    Write-Host ("[FATAL] 行为 harness 不存在: " + $harness)
    Write-Host 'VERIFY RESULT: FAIL (0/0)'
    exit 2
}

$goExe = $null
if (-not $SkipGo) {
    $goCmd = Get-Command go -ErrorAction SilentlyContinue
    if ($goCmd) { $goExe = $goCmd.Source }
}

# ── 1. go build ───────────────────────────────────────────────────────────
if ($SkipGo) {
    Write-Host '[SKIP] go build ./...    (按 -SkipGo 跳过)'
} elseif (-not $goExe) {
    Add-Result 'go:available' $false 'go 不在 PATH 中, 无法执行 build/test'
} else {
    Write-Host '--- 1/4 go build ./... ---'
    $r = Invoke-Child -FilePath $goExe -Arguments 'build ./...' -WorkingDirectory $csDir -TimeoutSec 300
    Add-Result 'go:build' ($r.ExitCode -eq 0) $(if ($r.ExitCode -eq 0) { 'config-server 编译通过' } else { "exit=" + $r.ExitCode })
    if ($r.ExitCode -ne 0 -or $r.TimedOut) { Write-ChildOutput $r }

    # ── 2. go test ────────────────────────────────────────────────────────
    Write-Host '--- 2/4 go test ./... ---'
    $r = Invoke-Child -FilePath $goExe -Arguments 'test ./...' -WorkingDirectory $csDir -TimeoutSec 300
    Add-Result 'go:test' ($r.ExitCode -eq 0) $(if ($r.ExitCode -eq 0) { 'config-server 测试通过' } else { "exit=" + $r.ExitCode })
    if ($r.ExitCode -ne 0 -or $r.TimedOut) { Write-ChildOutput $r }
}

# ── 3. AHK 编译校验 ───────────────────────────────────────────────────────
# 注意: **不要** 单独 /validate bin\lib\*.ahk。
# lib 文件不是独立脚本, 单独编译会因跨文件符号未解析触发 #Warn 对话框而阻塞
# (实测 60s 超时, exit=-2), 这既慢又会弹出窗口污染桌面。
# bin\MyKeymap.ahk 通过 #Include 把所有 lib 纳入同一次编译, 校验它即等于校验
# 全部 lib 的语法; harness 自身单独校验一次(它有自己的 include 集合)。
Write-Host '--- 3/4 AHK 编译校验 (/validate, 不执行脚本) ---'
$validateTargets = @(
    @{ Name = 'validate:bin/MyKeymap.ahk';     Path = (Join-Path $repoRoot 'bin\MyKeymap.ahk') },
    @{ Name = 'validate:test/harness/lib_test.ahk'; Path = $harness }
)
foreach ($t in $validateTargets) {
    if (-not (Test-Path $t.Path)) {
        Add-Result $t.Name $false '文件不存在'
        continue
    }
    $validateArgs = '/ErrorStdOut /validate "' + $t.Path + '"'
    $r = Invoke-Child -FilePath $ahkExe -Arguments $validateArgs -WorkingDirectory $repoRoot -TimeoutSec 60
    $ok = ($r.ExitCode -eq 0)
    $detail = if ($ok) { '语法通过' } else { "exit=" + $r.ExitCode + " " + (($r.StdOut + $r.StdErr) -replace '\s+', ' ').Trim() }
    Add-Result $t.Name $ok $detail
}

# ── 4. 行为断言 harness ───────────────────────────────────────────────────
Write-Host '--- 4/4 行为断言 harness (T1..T6) ---'
$harnessArgs = '/ErrorStdOut "' + $harness + '"'
$r = Invoke-Child -FilePath $ahkExe -Arguments $harnessArgs -WorkingDirectory $repoRoot -TimeoutSec $HarnessTimeoutSec

$harnessLog = Join-Path $repoRoot '_harness_run.log'
$passLines = 0
$failLines = 0
# 日志每行形如 "09:02:03 PASS: T1/..." (带 HH:mm:ss 前缀), 因此不能锚定行首。
$passPattern = '(?:^|\s)PASS: '
$failPattern = '(?:^|\s)FAIL: '
if (Test-Path $harnessLog) {
    $logLines = Get-Content -LiteralPath $harnessLog -Encoding UTF8
    foreach ($l in $logLines) {
        if ($l -match $failPattern) { $failLines += 1 }
        elseif ($l -match $passPattern) { $passLines += 1 }
    }
    Write-Host ('    断言明细 (来自 _harness_run.log):')
    foreach ($l in $logLines) {
        if ($l -match $passPattern -or $l -match $failPattern) {
            # 去掉时间戳前缀, 只留机器可读的 PASS:/FAIL: 行
            Write-Host ('      ' + ($l -replace '^\d{2}:\d{2}:\d{2}\s+', ''))
        }
    }
} else {
    Write-Host '    [warn] 未找到 _harness_run.log, 无法统计断言明细'
    Write-ChildOutput $r
}

$harnessOk = ($r.ExitCode -eq 0) -and ($failLines -eq 0) -and ($passLines -gt 0)
$harnessDetail = "exit=$($r.ExitCode), PASS=$passLines, FAIL=$failLines"
if ($r.TimedOut) { $harnessDetail += ', TIMEOUT' }
Add-Result 'harness:T1..T6 行为断言' $harnessOk $harnessDetail

# harness 异常终止时把原始输出也打出来, 便于排查
if (-not $harnessOk) {
    Write-ChildOutput $r
    if ($r.StdErr -and $r.StdErr.Trim()) {
        Write-Host '    --- harness stderr ---'
        Write-Host ('    ' + $r.StdErr.TrimEnd())
    }
}

# ── 收尾: 确保不残留 AHK 进程(仅本仓库 exe 路径的进程) ────────────────────
$leftovers = Get-CimInstance Win32_Process -Filter "Name='AutoHotkey64.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.ExecutablePath -eq $ahkExe }
foreach ($p in $leftovers) {
    Write-Host ("[cleanup] 终止残留 AHK 进程 pid=" + $p.ProcessId)
    try { Stop-Process -Id $p.ProcessId -Force -ErrorAction Stop } catch {}
}

# ── 汇总 ─────────────────────────────────────────────────────────────────
Write-Host ''
Write-Host '=========================================================='
Write-Host ' 汇总'
Write-Host '=========================================================='
foreach ($r in $results) {
    $line = "  {0,-6} {1}" -f $r.Status, $r.Name
    if ($r.Detail) { $line += "   ($($r.Detail))" }
    Write-Host $line
}
Write-Host ''
Write-Host ("  行为断言: PASS={0} FAIL={1}" -f $passLines, $failLines)

if ($failCount -eq 0) {
    Write-Host ("VERIFY RESULT: PASS ({0}/{0})" -f $total)
    exit 0
} else {
    Write-Host ("VERIFY RESULT: FAIL ({0}/{1})" -f $failCount, $total)
    exit 1
}
