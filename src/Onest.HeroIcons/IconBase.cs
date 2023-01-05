using Microsoft.AspNetCore.Components;

namespace Onest.HeroIcons;

public class IconBase : ComponentBase
{
    [Parameter(CaptureUnmatchedValues = true)]
    public Dictionary<string, object>? Attributes { get; set; }
}
