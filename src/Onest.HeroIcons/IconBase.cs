using Microsoft.AspNetCore.Components;

namespace Onest.HeroIcons.Internal;

public class IconBase : ComponentBase
{
    [Parameter(CaptureUnmatchedValues = true)]
    public Dictionary<string, object>? Attributes { get; set; }
}
