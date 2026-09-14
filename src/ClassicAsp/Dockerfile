FROM mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2022

# The IIS image includes the web server, but Classic ASP must be enabled.
RUN powershell -NoProfile -Command "$ErrorActionPreference = 'Stop'; $result = Install-WindowsFeature Web-ASP; if (-not $result.Success) { throw 'Classic ASP installation failed.' }"

# Replace the stock IIS welcome page with this self-contained application.
RUN powershell -NoProfile -Command "$ErrorActionPreference = 'Stop'; Remove-Item -Recurse -Force C:/inetpub/wwwroot/*"
COPY site/ C:/inetpub/wwwroot/

EXPOSE 80

# Inherit the image's ServiceMonitor entrypoint, which supervises IIS (W3SVC).
