using System;
using System.IO;
using System.Text.RegularExpressions;
using StreamDeckLib;
using StreamDeckLib.Messages;
using System.Threading.Tasks;
using WindowsInput.Native;
using WindowsInput;
using JetBrains.Annotations;
using Serilog;

[ActionUuid(Uuid = "com.scottbilas.sfactory.macro"), UsedImplicitly]
partial class MacroAction : BaseStreamDeckAction
{
    Func<Task>? _action;

    public override Task OnKeyUp(StreamDeckEventPayload args) => _action?.Invoke() ?? Task.CompletedTask;
    public override Task OnDidReceiveSettings(StreamDeckEventPayload args) => ApplySettings(args);
    public override Task OnWillAppear(StreamDeckEventPayload args) => ApplySettings(args);

    public override Task OnDidReceiveGlobalSettings(StreamDeckEventPayload args)
    {
        return base.OnDidReceiveGlobalSettings(args);
    }

    async Task ApplySettings(StreamDeckEventPayload args)
    {
        var settings = args.payload.settings;
        var macroName = (string)settings.Name;
        var variantName = (string)settings.Variant;
        var allVariants = (string[])settings.AllVariants;

        Log.Verbose("ApplySettings: " + Regex.Replace(settings.ToString(), @"\s+", " "));

        if (macroName == "HotBar")
        {
            var hotBarNumber = int.Parse(variantName);
            var sim = new InputSimulator();

            Log.Verbose($"{args.payload.coordinates.column},{args.payload.coordinates.row} = HotBar {hotBarNumber}");

            var imageName = $"images/hotbars/hotbar_{hotBarNumber}.png";

            await Manager.SetTitleAsync(args.context, "");
            await Manager.SetImageAsync(args.context, imageName);

            _action = () =>
            {
                sim.Keyboard.KeyPress(VirtualKeyCode.MENU);
                sim.Keyboard.Sleep(50);
                sim.Keyboard.KeyPress(VirtualKeyCode.VK_0 + hotBarNumber);

                return Task.CompletedTask;
            };
        }
        else if (macroName != null)
        {
            var sim = new InputSimulator();

            Log.Verbose($"{args.payload.coordinates.column},{args.payload.coordinates.row} = Buildable '{macroName}'");

            var imageName = "images/buildables/" + macroName.Replace(' ', '_');
            if (!string.IsNullOrEmpty(variantName))
                imageName += $"_({variantName.Replace(' ', '_')})";

            imageName += ".png";
            if (!File.Exists(imageName))
            {
                Log.Verbose($"Image does not exist: {imageName}");
                imageName = File.Exists(imageName) ? imageName : "images/plugin/plugin.png";
            }

            var title = "";
            var match = TitleDecorationRx().Match(macroName);
            if (match.Success)
                title = match.Groups[1].Value;

            await Manager.SetTitleAsync(args.context, title);
            await Manager.SetImageAsync(args.context, imageName);

            _action = () =>
            {
                sim.Keyboard.KeyDown(VirtualKeyCode.VK_N); // default hotkey for search bar (TODO: make a global setting)
                sim.Keyboard.Sleep(50);
                sim.Keyboard.TextEntry(macroName);
                sim.Keyboard.Sleep(50);

                sim.Keyboard.KeyDown(VirtualKeyCode.RETURN);
                sim.Keyboard.Sleep(50);
                sim.Keyboard.KeyUp(VirtualKeyCode.RETURN);

                return Task.CompletedTask;
            };
        }
        else
            _action = null;
    }

    [GeneratedRegex(" ([0-9.]+m|Mk\\.\\d+)")]
    private static partial Regex TitleDecorationRx();
}
