. "$PSScriptRoot\lib.ps1"
Start-Step '01-local-test' 'Unit tests and Docker image build on the developer machine'
& docker run --rm -v "${ProjectRoot}\app:/app" -w /app node:20-alpine sh -c "npm ci --no-audit --no-fund && npm test" | Out-Host
if ($LASTEXITCODE -ne 0) { Save-Screenshot '01-local-test-FAILED'; exit 1 }
Exec 'docker build -t incidentiq:local app'
Exec 'docker images incidentiq:local'
End-Step 'Tests passed and image built'
