param(
    [string]$Serial = 'emulator-5554',
    [ValidateSet(
        'integration_test/app_flow_test.dart',
        'integration_test/profile_editor_landscape_test.dart',
        'integration_test/open_source_licenses_test.dart',
        'integration_test/group_choices_test.dart',
        'integration_test/g10_compact_test.dart',
        'integration_test/g14_variants_test.dart',
        'integration_test/g02_session_test.dart',
        'integration_test/g55_session_test.dart',
        'integration_test/family_pages_landscape_test.dart',
        'integration_test/onboarding_landscape_flow_test.dart',
        'integration_test'
    )]
    [string]$TestTarget = 'integration_test/app_flow_test.dart'
)
$ErrorActionPreference = 'Stop'
if ($Serial -notmatch '^emulator-[0-9]+$') { throw 'Only an Android emulator is allowed.' }
$root = Split-Path $PSScriptRoot -Parent
$adb = Join-Path $env:LOCALAPPDATA 'Android/Sdk/platform-tools/adb.exe'
function Device([string[]]$Arguments) {
    $output = & $adb -s $Serial @Arguments
    if ($LASTEXITCODE -ne 0) { throw 'Emulator command failed.' }
    return ($output -join "`n").Trim()
}
function NetworkLine {
    return ((Device @('shell','dumpsys','connectivity')) -split "`n" |
        Where-Object { $_ -match '^Active default network:' } | Select-Object -First 1)
}
$before = [ordered]@{
    airplane = Device @('shell','settings','get','global','airplane_mode_on')
    wifi = Device @('shell','settings','get','global','wifi_on')
    data = Device @('shell','settings','get','global','mobile_data')
}
foreach ($value in $before.Values) {
    if ($value -notin @('0','1')) { throw 'Cannot safely restore unknown emulator network state.' }
}
$result = [ordered]@{
    testedAtUtc = [DateTime]::UtcNow.ToString('o')
    serial = $Serial
    testTarget = $TestTarget
    before = $before
    offlineNetwork = $null
    testExitCode = $null
    restored = $false
}
$testExit = 1
Push-Location $root
try {
    Device @('shell','cmd','connectivity','airplane-mode','enable') | Out-Null
    Device @('shell','svc','wifi','disable') | Out-Null
    Device @('shell','svc','data','disable') | Out-Null
    for ($attempt = 0; $attempt -lt 10; $attempt++) {
        $line = NetworkLine
        if ($line -and $line -notmatch ':\s*[0-9]+\s*$') { break }
        Start-Sleep -Milliseconds 500
    }
    if (-not $line -or $line -match ':\s*[0-9]+\s*$') {
        throw 'Offline state was not verified; tests were not started.'
    }
    $result.offlineNetwork = $line.Trim()
    if ($TestTarget -in @('integration_test/group_choices_test.dart', 'integration_test/g14_variants_test.dart', 'integration_test/g02_session_test.dart', 'integration_test/g55_session_test.dart', 'integration_test/family_pages_landscape_test.dart', 'integration_test/onboarding_landscape_flow_test.dart')) {
        & flutter drive --driver=test_driver/integration_test.dart --target=$TestTarget -d $Serial --no-pub *> artifacts/latest-android-offline-test.log
    } else {
        & flutter test $TestTarget -d $Serial --no-pub *> artifacts/latest-android-offline-test.log
    }
    $testExit = $LASTEXITCODE
    $result.testExitCode = $testExit
}
finally {
    $mode = if ($before.airplane -eq '1') { 'enable' } else { 'disable' }
    Device @('shell','cmd','connectivity','airplane-mode',$mode) | Out-Null
    $wifi = if ($before.wifi -eq '1') { 'enable' } else { 'disable' }
    $data = if ($before.data -eq '1') { 'enable' } else { 'disable' }
    Device @('shell','svc','wifi',$wifi) | Out-Null
    Device @('shell','svc','data',$data) | Out-Null
    $after = $null
    for ($attempt = 0; $attempt -lt 10; $attempt++) {
        $after = [ordered]@{
            airplane = Device @('shell','settings','get','global','airplane_mode_on')
            wifi = Device @('shell','settings','get','global','wifi_on')
            data = Device @('shell','settings','get','global','mobile_data')
        }
        if ($after.airplane -eq $before.airplane -and
            $after.wifi -eq $before.wifi -and
            $after.data -eq $before.data) { break }
        Start-Sleep -Milliseconds 500
    }
    $result.after = $after
    $result.restored = $after.airplane -eq $before.airplane -and
        $after.wifi -eq $before.wifi -and $after.data -eq $before.data
    $result | ConvertTo-Json -Depth 5 | Set-Content artifacts/compliance/android-offline-qa.json
    Pop-Location
}
if (-not $result.restored) { throw 'Emulator network restoration needs attention.' }
exit $testExit


