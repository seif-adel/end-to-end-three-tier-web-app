param(
  [string]$TerraformDir = "./infra/terraform",
  [string]$FrontendConfigPath = "./frontend/config.js"
)

# Resolve paths relative to repository root regardless of current shell location.
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$terraformDirResolved = (Resolve-Path (Join-Path $repoRoot $TerraformDir)).Path
$frontendConfigResolved = Join-Path $repoRoot $FrontendConfigPath

$terraformExe = "terraform"
if (Test-Path "C:\Program Files\terraform\terraform.exe") {
  $terraformExe = "C:\Program Files\terraform\terraform.exe"
}

$apiUrl = & $terraformExe "-chdir=$terraformDirResolved" output -raw api_base_url
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($apiUrl)) {
  throw "Failed to read api_base_url from Terraform output. Ensure terraform apply has completed successfully."
}

$content = @"
window.APP_CONFIG = {
  apiBaseUrl: "$apiUrl"
};
"@

Set-Content -Path $frontendConfigResolved -Value $content -NoNewline
Write-Host "Updated $frontendConfigResolved with apiBaseUrl=$apiUrl"
