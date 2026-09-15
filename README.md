# Classic ASP Container Hello World

A minimal Classic ASP application running in an IIS Windows container. The page renders **Hello World** and a server timestamp using VBScript. A separate `health.asp` endpoint confirms that IIS can execute ASP requests.

## Requirements

- An Intel/AMD Windows 11 Pro or Enterprise PC with virtualization and Windows-container prerequisites enabled.
- Docker Desktop running in **Windows containers** mode. Use its tray menu to switch from Linux containers if needed.

No .NET SDK or Visual Studio is required. You can edit the source on macOS, but this IIS image must be built and run on a Windows container host.

## Build and run

Clone the repository on the Windows PC using a GitHub account with access, then open PowerShell in its directory:

```powershell
git clone https://github.com/StephenBertrand/classic-asp-container-hello-world.git
cd classic-asp-container-hello-world
```

Check that Docker is using the Windows engine:

```powershell
docker info --format '{{.OSType}}'
```

It should report `windows`. Build the image and start a new container:

```powershell
docker build -t classic-asp-hello:local ./src/ClassicAsp
docker run --rm --name classic-asp-hello -p 8080:80 classic-asp-hello:local
```

No existing image or container is required. The first build downloads the Windows Server Core/IIS base image, which is several gigabytes, and enables Classic ASP. Subsequent builds reuse cached layers.

Open **<http://localhost:8080/>**. Refresh the page to see the server time change. The timestamp uses the container's local time.

The run command stays attached to the container. In a second PowerShell window, stop it with:

```powershell
docker stop classic-asp-hello
```

The `--rm` option removes the container after it stops; the built image remains available. After changing ASP files, stop the container and repeat the build and run commands to include your changes.

## Verify the application

With the container running, open another PowerShell window in the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/Test-Demo.ps1
```

The smoke check verifies HTTP 200 responses, the Hello World default page, a rendered server timestamp, and the exact `ok` response from `/health.asp`. It exits with an error on failure. The execution-policy override applies only to this PowerShell process.

## Files

| File | Purpose |
| --- | --- |
| `src/ClassicAsp/Dockerfile` | Enables Classic ASP in Microsoft's IIS image and copies in the site. |
| `src/ClassicAsp/site/default.asp` | Executes VBScript and renders the Hello World page. |
| `src/ClassicAsp/site/health.asp` | Returns `ok` after executing ASP. |
| `src/ClassicAsp/site/web.config` | Configures `default.asp` as the default document. |
| `scripts/Test-Demo.ps1` | Checks the running application over HTTP. |

The image uses Windows Server Core LTSC 2022 and inherits the official IIS image's `ServiceMonitor` entrypoint to supervise IIS. The site is copied into the image, with no database, external COM components, or local source mounts. This is a local development sample.

## Troubleshooting

- **Docker reports `linux`:** Switch Docker Desktop to Windows containers. If the option is missing, check your Windows edition and Docker installation.
- **Host/container OS mismatch:** Check [Microsoft's compatibility guidance](https://learn.microsoft.com/en-us/virtualization/windowscontainers/deploy-containers/version-compatibility). On a compatible host with Hyper-V enabled, try adding `--isolation=hyperv` to the `docker run` command before the image name.
- **Port 8080 is in use:** Stop the previous container or use `-p 8081:80`, browse to port 8081, and pass `-BaseUri http://localhost:8081/` to the smoke check.
- **Container name is already in use:** Inspect `docker ps -a` and stop the earlier demo container before starting another with the same name.
- **HTTP 500:** Check `/health.asp` and the IIS logs inside the container at `C:\inetpub\logs\LogFiles`. IIS request logs and detailed ASP errors are not automatically streamed by `docker logs`.

## Validation status

The Dockerfile was successfully built and the Hello World page served on the Windows test PC before the project was simplified to Docker only. The current page-label and documentation changes have been reviewed locally; the updated smoke check flow still needs to be run on Windows. Windows containers cannot be executed on the development Mac.

## References

- [Microsoft IIS container image](https://github.com/microsoft/iis-docker)
- [Windows container prerequisites](https://learn.microsoft.com/en-us/virtualization/windowscontainers/deploy-containers/system-requirements)
- [Classic ASP on IIS](https://learn.microsoft.com/en-us/iis/application-frameworks/running-classic-asp-applications-on-iis-7-and-iis-8/classic-asp-not-installed-by-default-on-iis)
