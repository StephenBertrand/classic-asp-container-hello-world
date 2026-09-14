<%@ Language="VBScript" CodePage="65001" %>
<%
Option Explicit
Response.ContentType = "text/html"
Response.Charset = "utf-8"
Response.AddHeader "Cache-Control", "no-store"

Dim serverTime
serverTime = Now()
%>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Hello World | Classic ASP + Aspire</title>
    <style>
        body { margin: 4rem auto; padding: 0 1.5rem; max-width: 40rem;
               font: 1.125rem/1.6 system-ui, sans-serif; color: #18212b; }
        h1 { font-size: 2.5rem; line-height: 1.15; }
        .eyebrow { color: #526172; font-size: .9rem; }
        code { background: #f1f4f7; padding: .2rem .4rem; border-radius: .25rem; }
        a { color: #175b99; }
    </style>
</head>
<body>
    <main>
        <p class="eyebrow">Classic ASP + IIS + Aspire</p>
        <h1>Hello World</h1>
        <p>This page was rendered by VBScript inside an IIS Windows container.</p>
        <p>Server time: <code id="server-time"><%= Server.HTMLEncode(CStr(serverTime)) %></code></p>
        <p>Refresh the page to see the server time change.</p>
        <p><a href="health.asp">Check ASP health</a></p>
    </main>
</body>
</html>
