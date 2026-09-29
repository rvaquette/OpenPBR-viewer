# Azure Function Deployment Plan

## Status

 Ready for Validation (local and IaC checks complete; Azure region/SKU lookup requires an accessible subscription context)

## Goal

Add an HTTP Azure Function for the GitHub Pages frontend. The function receives a
MaterialX generation request, calls a configured Copilot-compatible model
endpoint, validates the returned MaterialX XML, and returns it to the viewer.

## Scope

- Add a Node.js Azure Functions v4 HTTP endpoint: `POST /api/copilot/mtlx`.
- Accept JSON containing `prompt`, `format`, and optional generation metadata.
- Return JSON containing `mtlx`, or a structured error response.
- Keep model credentials and endpoint configuration in Function App application
  settings only. Never expose them to the browser or commit them to the repo.
- Restrict CORS to the deployed GitHub Pages origin and localhost development.
- Add Bicep infrastructure and deployment scripts for a Linux Consumption/Flex
  Consumption Function App, Storage Account, and Application Insights.
- Add local settings template and README instructions without real secrets.

## Assumption Requiring Confirmation

The Azure Function will call a Copilot-compatible HTTP endpoint configured with:

- `COPILOT_API_URL`
- `COPILOT_API_KEY`
- `COPILOT_MODEL`

The function adapter will use an OpenAI-compatible chat request/response shape
unless the actual Copilot gateway contract requires a small adapter change.
GitHub Copilot credentials or a personal token will not be placed in the static
GitHub Pages application.

## Proposed Files

- `api/package.json`
- `api/host.json`
- `api/local.settings.json.example`
- `api/src/functions/generateMtlx.js`
- `api/src/lib/copilotClient.js`
- `api/src/lib/mtlxValidation.js`
- `infra/main.bicep`
- `infra/main.bicepparam.example`
- `scripts/deploy-function.ps1`
- `api/README.md`

## Security and Reliability

- Validate method, content type, body size, prompt length, and XML root/material
  elements.
- Use an explicit system prompt requiring MaterialX 1.39 XML only.
- Use request timeouts and do not log prompts, XML, or secret values.
- Return generic upstream errors to the browser and detailed diagnostics only
  in Application Insights traces.
- Configure CORS through an application setting used by the Function App.
- Use managed identity for Application Insights where supported; model secret
  remains an application setting because the requested upstream contract uses a
  secret key.

## Validation

- `npm install` and `npm run build` in `api`.
- Local HTTP smoke test with a mocked Copilot-compatible endpoint.
- Bicep validation and what-if when Azure context is available.
- Verify the GitHub Pages frontend can call the deployed endpoint with CORS.

## Deployment Boundary

This plan prepares code and infrastructure only. It does not provision Azure
resources or deploy until the user explicitly requests deployment and provides
the subscription, resource group, and location.

## Azure Context

- Subscription: `cd45df20-ad5a-4597-87e5-2973892d84ae`
- Resource group: `rg-webgl`
- Portal: `https://portal.azure.com/#@softfluent.com/resource/subscriptions/cd45df20-ad5a-4597-87e5-2973892d84ae/resourceGroups/rg-webgl/overview`
- Location: pending Azure read access
- Current blocker: the local Azure CLI refresh token expired; run `az login`
  before region/SKU validation or deployment.

## Validation Proof

- `Push-Location api; npm run build`: passed.
- `npm run build`: passed.
- `az bicep build --file infra/main.bicep`: passed.
- Azure Bicep MCP compilation: passed with no diagnostics.
- PowerShell parser validation for `scripts/deploy-function.ps1`: passed.
- `appmod-get-available-region-sku`: blocked because the current Azure CLI
  subscription was rejected by the availability service; no resource was created.

## Applied IaC Rules

- Function App uses a user-assigned managed identity.
- Storage Blob Data Owner, Storage Blob Data Contributor, Storage Queue Data
  Contributor, Storage Table Data Contributor, and Monitoring Metrics Publisher
  role assignments are declared.
- Storage anonymous blob access and shared-key access are disabled.
- Function storage uses identity-based `AzureWebJobsStorage__*` settings.
- Function App, Storage, App Insights, plan, identity, workspace, and diagnostic
  resources use deterministic `az...` names from `uniqueString`.
- Diagnostic settings send Function App logs and metrics to Log Analytics.
- A `function.json` file is included alongside the code-based registration.