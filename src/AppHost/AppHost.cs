var builder = DistributedApplication.CreateBuilder(args);

// Use the direct Docker build path, with output visible in the dashboard.
// The working directory is relative to the AppHost project.
var imageBuild = builder.AddExecutable("classic-asp-build", "docker", "../ClassicAsp",
    "build", "-t", "classic-asp-hello:local", ".");

builder.AddContainer("classic-asp", "classic-asp-hello", "local")
    .WaitForCompletion(imageBuild)
    .WithImagePullPolicy(ImagePullPolicy.Never)
    .WithHttpEndpoint(port: 8080, targetPort: 80, name: "http", isProxied: false)
    .WithHttpHealthCheck("/health.asp");

builder.Build().Run();
