var builder = DistributedApplication.CreateBuilder(args);

// Relative to this AppHost project, not the shell's working directory.
builder.AddDockerfile("classic-asp", "../ClassicAsp")
    .WithHttpEndpoint(port: 8080, targetPort: 80, name: "http", isProxied: false)
    .WithHttpHealthCheck("/health.asp");

builder.Build().Run();
