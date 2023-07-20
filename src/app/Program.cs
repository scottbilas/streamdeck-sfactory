using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using Microsoft.Extensions.Logging;
using Serilog;
using StreamDeckLib;

// very useful when working with streamdeck-launched exe, can be enabled when building with..
//
// dotnet:  -p:WaitForDebugger=true
// dev.ps1: -BuildWithDebuggerWait
//
#if WAIT_FOR_DEBUGGER

Console.Write($"Waiting for debugger to attach (this is process {Environment.ProcessId})...");
while (!Debugger.IsAttached)
{
    System.Threading.Thread.Sleep(500);
    Console.Write(".");
}
Console.WriteLine("attached!");

Console.Write("Breaking into debugger...");
Debugger.Break();
Console.Write("continuing!");

#endif // WAIT_FOR_DEBUGGER

var exeDir = Path.GetDirectoryName(Environment.ProcessPath);
Directory.SetCurrentDirectory(exeDir!);

// note: can't use json-based config for serilog because it does silly things with looking for name-prefixed dll's,
// and that doesn't work with single-file publish.

Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Verbose()
    .WriteTo.File(
        "../../logs/com.scottbilas.sfactory.log",
        rollingInterval: RollingInterval.Day,
        outputTemplate: "{Timestamp:yyyy-MM-dd HH:mm:ss.fff} [{Level:u3}] {Message} {NewLine}{Exception}")
    .Enrich.FromLogContext()
    .CreateLogger();

using var loggerFactory = new LoggerFactory()
    .AddSerilog(Log.Logger);

await ConnectionManager
    .Initialize(args, loggerFactory)
    .RegisterAllActions(Assembly.GetExecutingAssembly())
    .StartAsync();

// give a chance to debug before exit
if (Debugger.IsAttached)
	Debugger.Break();
