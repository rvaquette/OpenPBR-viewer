# MaterialX Copilot Function

This Azure Function exposes two endpoints for the viewer:

- `POST /api/copilot/mtlx` generates a MaterialX document and returns `{ "mtlx": "..." }`.
- `GET /api/mtlx/archive?url=<AmbientCG ZIP URL>` proxies an AmbientCG ZIP so browser clients can read it despite AmbientCG's missing CORS headers.

The archive endpoint only accepts HTTPS ZIP URLs from `ambientcg.com` and its
`acg-download.struffelproductions.com` download host. Archives are limited to
200 MiB. The response CORS policy uses `ALLOWED_ORIGINS`; the local fallback
allows Vite on `localhost:5173` and `127.0.0.1:5173`.

## Local configuration

Copy `local.settings.json.example` to `local.settings.json` and set the values
locally. Never commit that file or a real API key.

Run the API in one terminal:

```powershell
cd api
npm install
npm run build
func start
```

Run the viewer in a second terminal from the repository root:

```powershell
npx vite --port 5173
```

Vite forwards `/api/*` requests to Functions Core Tools on port `7071`.

## Deployment

Use `scripts/deploy-function.ps1` from a PowerShell session with Azure CLI
installed and authenticated. Set `COPILOT_API_KEY` from a protected CI/CD secret
or a local secret store before invoking the script. Do not commit or echo it:

```powershell
$env:COPILOT_API_KEY = $protectedSecretValue
```

The Bicep parameter is secure and the Function App reads the resulting
`COPILOT_API_KEY` application setting at runtime.

For a static production build, set `VITE_AMBIENTCG_ARCHIVE_ENDPOINT` to the
deployed `/api/mtlx/archive` URL before running `npm run build`, or set
`window.OPENPBR_AMBIENTCG_ARCHIVE_ENDPOINT` in the page configuration.
