param(
    [Uri]$BaseUri = 'http://localhost:8080/'
)

$ErrorActionPreference = 'Stop'
$root = $BaseUri.AbsoluteUri.TrimEnd('/')

$health = Invoke-WebRequest -Uri "$root/health.asp" -UseBasicParsing -TimeoutSec 15
if ($health.StatusCode -ne 200 -or $health.Content.Trim() -ne 'ok') {
    throw 'The ASP health endpoint did not return HTTP 200 with the expected body.'
}

$page = Invoke-WebRequest -Uri "$root/" -UseBasicParsing -TimeoutSec 15
if ($page.StatusCode -ne 200 -or $page.Content -notmatch '<h1>Hello World</h1>') {
    throw 'The default document did not return the Hello World page.'
}
if ($page.Content -match '<%' -or $page.Content -notmatch 'id="server-time">[^<]+</code>') {
    throw 'The page does not contain a rendered server time, or ASP source was returned.'
}

Write-Host 'PASS: IIS served the default page, executed Classic ASP, and returned a healthy response.'
