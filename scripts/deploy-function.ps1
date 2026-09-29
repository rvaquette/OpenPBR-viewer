param(
    [Parameter(Mandatory = $true)] [string] $ResourceGroup,
    [Parameter(Mandatory = $true)] [string] $Location,
    [Parameter(Mandatory = $true)] [string] $CopilotApiUrl,
    [Parameter(Mandatory = $true)] [string] $CopilotModel,
    [Parameter(Mandatory = $true)] [string] $AllowedOrigins
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$apiRoot = Join-Path $repoRoot 'api'
$packagePath = Join-Path $repoRoot '.azure-function-package.zip'
$deploymentName = "openpbr-$([DateTime]::UtcNow.ToString('yyyyMMddHHmmss'))"

if (-not $env:COPILOT_API_KEY) {
    throw 'Set COPILOT_API_KEY in the current PowerShell session before deployment.'
}

az group create --name $ResourceGroup --location $Location | Out-Null
az deployment group create `
    --name $deploymentName `
    --resource-group $ResourceGroup `
    --template-file (Join-Path $repoRoot 'infra/main.bicep') `
    --parameters environmentName=dev copilotApiUrl=$CopilotApiUrl copilotApiKey=$env:COPILOT_API_KEY copilotModel=$CopilotModel allowedOrigins=$AllowedOrigins | Out-Null

$FunctionAppName = az deployment group show --resource-group $ResourceGroup --name $deploymentName --query properties.outputs.functionAppName.value -o tsv

Push-Location $apiRoot
try {
    npm install --omit=dev
} finally {
    Pop-Location
}

if (Test-Path $packagePath) { Remove-Item $packagePath -Force }
Compress-Archive -Path (Join-Path $apiRoot '*') -DestinationPath $packagePath -Force
az functionapp deployment source config-zip --resource-group $ResourceGroup --name $FunctionAppName --src $packagePath
Remove-Item $packagePath -Force
Write-Output "Copilot endpoint: https://$FunctionAppName.azurewebsites.net/api/copilot/mtlx"
Write-Output "AmbientCG ZIP endpoint: https://$FunctionAppName.azurewebsites.net/api/mtlx/archive"
