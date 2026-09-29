# MaterialX Copilot Function

This Azure Function exposes `POST /api/copilot/mtlx` for the GitHub Pages viewer.
It expects a Copilot-compatible OpenAI chat endpoint and returns `{ "mtlx": "..." }`.

## Local configuration

Copy `local.settings.json.example` to `local.settings.json` and set the values
locally. Never commit that file or a real API key.

Run:

```powershell
npm install
npm run build
func start
```

## Deployment

Use `scripts/deploy-function.ps1` from a PowerShell session with Azure CLI
installed and authenticated. Set `COPILOT_API_KEY` from a protected CI/CD secret
or a local secret store before invoking the script. Do not commit or echo it:

```powershell
$env:COPILOT_API_KEY = $protectedSecretValue
```

The Bicep parameter is secure and the Function App reads the resulting
`COPILOT_API_KEY` application setting at runtime.
