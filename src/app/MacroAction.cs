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

    async Task ApplySettings(StreamDeckEventPayload args)
    {
        var settings = args.payload.settings;

        Log.Verbose("Settings: " + Regex.Replace(settings.ToString(), @"\s+", " "));

        if (settings.BuildingMacro != null)
        {
            var buildingType = (string)settings.BuildingMacro.Type;
            var sim = new InputSimulator();

            Log.Verbose($"{args.payload.coordinates.column},{args.payload.coordinates.row} = BuildingMacro '{buildingType}'");

            var imageName = "images/buildings/" + buildingType.Replace(' ', '_') + ".png";
            if (!File.Exists(imageName))
            {
                var testName = imageName[..^4] + "_(FICSIT).png";
                imageName = File.Exists(testName) ? testName : "images/category/categoryIcon@2x.png";
            }

            var title = "";
            var match = TitleDecorationRx().Match(buildingType);
            if (match.Success)
                title = match.Groups[1].Value;

            await Manager.SetTitleAsync(args.context, title);
            await Manager.SetImageAsync(args.context, imageName);

            _action = () =>
            {
                sim.Keyboard.KeyDown(VirtualKeyCode.VK_N); // default hotkey for search bar (TODO: make a global setting)
                sim.Keyboard.Sleep(50);
                sim.Keyboard.TextEntry(buildingType);
                sim.Keyboard.Sleep(50);

                sim.Keyboard.KeyDown(VirtualKeyCode.RETURN);
                sim.Keyboard.Sleep(50);
                sim.Keyboard.KeyUp(VirtualKeyCode.RETURN);

                return Task.CompletedTask;
            };
        }
        else if (settings.HotBarMacro != null)
        {
            var hotBarNumber = (int)settings.HotBarMacro.Number;
            var sim = new InputSimulator();

            Log.Verbose($"{args.payload.coordinates.column},{args.payload.coordinates.row} = HotBarMacro {hotBarNumber}");

            var imageName = $"images/hotbars/hotbar_{hotBarNumber}.png";
            await Manager.SetImageAsync(args.context, imageName);

            _action = () =>
            {
                sim.Keyboard.KeyPress(VirtualKeyCode.MENU);
                sim.Keyboard.Sleep(50);
                sim.Keyboard.KeyPress(VirtualKeyCode.VK_0 + hotBarNumber);

                return Task.CompletedTask;
            };
        }
        else
            _action = null;
    }

    [GeneratedRegex(" ([0-9.]+m|Mk\\.\\d+)")]
    private static partial Regex TitleDecorationRx();
}
