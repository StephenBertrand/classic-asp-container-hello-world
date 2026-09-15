# Classic ASP with Aspire

A small Classic ASP application running in an IIS Windows container, with a C# Aspire AppHost intended to build, start, and monitor it.

**Current status:** Direct Docker build and execution have succeeded on the Windows test PC. Aspire startup is blocked by `unknown flag: --progress` during image build. Windows containers are not currently a supported Aspire scenario ([upstream issue](https://github.com/microsoft/aspire/issues/8063)). This repository preserves the standard `AddDockerfile` setup for investigation; it is not yet a working F5 sample.

The page renders **Hello World** and a server timestamp using VBScript. A separate `health.asp` endpoint lets Aspire check that IIS can execute ASP requests.

This is the first step in exploring how an existing Classic ASP application can participate in a modern development environment.

## Requirements

To **run** the demo:

- An Intel/AMD Windows 11 Pro or Enterprise PC with virtualization enabled and the Windows features needed for Windows containers. Windows ARM and Windows Home are not supported for this setup.
- Docker Desktop installed with Windows-container support. In Docker Desktop's tray menu, choose **Switch to Windows containers** if it is currently running Linux containers.
- The [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0). A runtime-only installation is insufficient.

The AppHost uses Aspire 13.5.3, restored through NuGet. An Aspire workload, the Aspire CLI, and Visual Studio are not required for the commands below.

You can edit the files and compile the AppHost on macOS, but run Aspire and the Windows container on the Windows PC. Transfer the source folder or clone the repository there; build outputs do not need to be copied.

## Reproduce Aspire startup on Windows

The following is the intended startup flow. It currently fails at image build with the compatibility issue described above. To run the working IIS image directly, see **Run the same image without Aspire** below.

Clone the private repository on your PC using a GitHub account with access:

```powershell
git clone https://github.com/StephenBertrand/classic-asp-aspire.git
cd classic-asp-aspire
```

Open PowerShell in the repository root. Check the prerequisites:

```powershell
dotnet --version
docker info --format '{{.OSType}}'
```

The first command should report `10.0.x`; the second must report `windows`.

Open `ClassicAspAspire.slnx` in Visual Studio with .NET 10 support, set `AppHost` as the startup project, select the `http` launch profile, and press **F5**. No prebuilt image or container is required.

Alternatively, start the same AppHost from PowerShell:

```powershell
dotnet run --project src/AppHost --launch-profile http
```

The AppHost declares the image build and container through `AddDockerfile`, without a separate build resource. The remaining steps describe the expected behavior once the build compatibility issue is resolved.

The first build downloads the Windows Server Core/IIS image and enables Classic ASP. The image is several gigabytes, so this initial build may take a while.

Open the dashboard URL printed in the terminal, including its login token if prompted. Wait for the `classic-asp` resource to become healthy, then open its HTTP endpoint:

**<http://localhost:8080/>**

Refresh the page to see the server time change. The time is local to the container and is not labeled as UTC.

In a second PowerShell window, run the smoke check:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/Test-Demo.ps1
```

This checks the default page, the rendered timestamp, and the exact ASP health response. It exits with an error if a check fails. The execution-policy override applies only to this PowerShell process.

Press **Ctrl+C** in the AppHost terminal to stop the application. After changing ASP files, stop and restart the AppHost. The build step runs again and Docker reuses unchanged cached layers. This version copies the site into the image rather than mounting a live source directory.

## How it fits together

```text
Windows PC
  Aspire AppHost
    builds the image and starts the IIS container through AddDockerfile
    checks GET /health.asp

  Browser -> localhost:8080 -> container port 80 -> IIS -> default.asp
```

| File | Purpose |
| --- | --- |
| `src/AppHost/AppHost.cs` | Describes the container, HTTP endpoint, and health check. |
| `src/ClassicAsp/Dockerfile` | Enables Classic ASP in Microsoft's IIS image and copies in the site. |
| `src/ClassicAsp/site/default.asp` | Executes VBScript and renders the demo page. |
| `src/ClassicAsp/site/health.asp` | Returns `ok` after executing ASP. |
| `src/ClassicAsp/site/web.config` | Makes `default.asp` the site's default document. |
| `scripts/Test-Demo.ps1` | Checks the running application over HTTP. |

## Design decisions

- **Windows Server Core with IIS:** Classic ASP depends on IIS and Windows. A Linux container cannot host this runtime. Docker must use a Windows engine to build and run the selected IIS image. The sample covers local development; Aspire deployment/publishing targets are not configured.
- **C# only for orchestration:** Aspire manages the application; the web page remains Classic ASP. There is no ASP.NET Core wrapper. The project deliberately uses NuGet-provided orchestration/dashboard tools rather than the optional Aspire CLI bundle, so only the SDK and Docker are needed. The related `ASPIRE010` advisory is suppressed explicitly.
- **Small container configuration:** Enable `Web-ASP`, install the site, and inherit the official image's `ServiceMonitor` entrypoint. No external COM components, certificates, databases, or company-specific configuration are needed.
- **Direct HTTP endpoint:** Docker publishes port 80 as host port 8080. Aspire's additional proxy is disabled because there is one instance and no service-discovery requirement.
- **Application health:** The check executes an `.asp` page, rather than checking only that the container process is running. This does not automatically instrument Classic ASP with OpenTelemetry traces or application logs.
- **Local development:** The launch profile uses HTTP to avoid a development certificate prerequisite. Keep the dashboard local. This is a development sample, not an internet deployment configuration.

## Troubleshooting

**Image build fails:** Inspect the `classic-asp` resource's console output and the AppHost output. Capture the error lines preceding the exit-code summary. Ensure Docker is running in Windows-container mode and `docker` is available on the IDE process PATH. Restart the IDE after installing Docker.

**Known Aspire compatibility issue (`unknown flag: --progress`, exit code 125):** Aspire's image-build command supplies a flag that Docker's legacy Windows builder does not accept. [Docker documents](https://docs.docker.com/reference/cli/docker/image/build/) that Windows-container mode uses the legacy builder. This explains why a direct `docker build` succeeds while the Aspire build fails before executing the Dockerfile. Aspire's [Windows-container support request](https://github.com/microsoft/aspire/issues/8063) remains open, and maintainers state that support is not currently planned or prioritized. No supported AppHost setting to remove this build flag has been identified. This repository retains `AddDockerfile` for reproduction; removing the flag alone would not establish full Windows-container compatibility.

**Switching from the direct Docker test:** Stop `classic-asp-test` with `docker stop classic-asp-test` before launching Aspire to free port 8080.

**Docker reports `linux`, or the Windows image cannot be pulled:** Switch Docker Desktop to Windows containers and check again. If that menu option is missing, check the Windows edition and whether Docker was installed with Windows-container support.

**The container OS does not match the host:** This sample targets the Windows Server 2022 IIS image. Update Windows and Docker Desktop, and check [Microsoft's Windows container compatibility guidance](https://learn.microsoft.com/en-us/virtualization/windowscontainers/deploy-containers/version-compatibility). For a compatible Windows 11 Pro/Enterprise PC with Hyper-V enabled, Hyper-V isolation can resolve a host/image mismatch. Add `.WithContainerRuntimeArgs("--isolation=hyperv")` to the container declaration if runtime isolation needs to be explicit.

**Port already in use:** Stop the service using port 8080 or change `port: 8080` in `AppHost.cs`. Pass the new address to `Test-Demo.ps1 -BaseUri http://localhost:YOUR_PORT/`. Dashboard ports are configured separately in `launchSettings.json`.

**HTTP 500 or unhealthy resource:** Look at the resource's console output and check `/health.asp`. IIS request logs and detailed ASP errors are not automatically forwarded to Aspire's console. First verify the image directly, as shown below, to separate IIS issues from orchestration issues.

## Run the same image without Aspire

These commands also require Windows-container mode. Stop the AppHost first so port 8080 is free.

```powershell
docker build -t classic-asp-hello:local ./src/ClassicAsp
docker run --rm --name classic-asp-hello -p 8080:80 classic-asp-hello:local
```

Open <http://localhost:8080/> and run the same smoke check from a second terminal. Stop the container with `docker stop classic-asp-hello`.

## Validation

Compile the AppHost on Windows or macOS:

```powershell
dotnet build ClassicAspAspire.slnx --configuration Release
```

A successful build verifies the C# orchestration project. It does **not** build the Windows image or execute VBScript. Complete the Windows run and smoke check above before claiming that the full demo has been tested.

## References

- [Aspire: Add an existing application](https://aspire.dev/get-started/add-aspire-existing-app/)
- [Microsoft IIS container image](https://github.com/microsoft/iis-docker)
- [Windows container prerequisites](https://learn.microsoft.com/en-us/virtualization/windowscontainers/deploy-containers/system-requirements)
- [Classic ASP on IIS](https://learn.microsoft.com/en-us/iis/application-frameworks/running-classic-asp-applications-on-iis-7-and-iis-8/classic-asp-not-installed-by-default-on-iis)
