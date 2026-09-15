var builder = DistributedApplication.CreateBuilder(args);

// Build first: docker build -t classic-asp-hello:local ./src/ClassicAsp
builder.AddContainer("classic-asp", "classic-asp-hello", "local")
    .WithImagePullPolicy(ImagePullPolicy.Never)
    .WithHttpEndpoint(port: 8080, targetPort: 80, name: "http", isProxied: false)
    .WithHttpHealthCheck("/health.asp");

builder.Build().Run();
