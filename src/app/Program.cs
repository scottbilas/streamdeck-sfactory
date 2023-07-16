using System.Reflection;
using StreamDeckLib;
using StreamDeckLib.Config;

using var config = ConfigurationBuilder.BuildDefaultConfiguration(args);

await ConnectionManager
    .Initialize(args, config.LoggerFactory)
    .RegisterAllActions(Assembly.GetExecutingAssembly())
    .StartAsync();
