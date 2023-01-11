$heroiconsRepositoryUrl = "https://github.com/tailwindlabs/heroicons.git"
$componentTemplatePath = "./component-template.razor"
$solidIconsLocalPath = "../src/Onest.HeroIcons/Solid/"
$outlineIconsLocalPath = "../src/Onest.HeroIcons/Outline/"
$miniIconsLocalPath = "../src/Onest.HeroIcons/Mini/"
$solidIconsRemotePath = "src/24/solid/*.svg"
$outlineIconsRemotePath = "src/24/outline/*.svg"
$miniIconsRemotePath = "src/20/solid/*.svg"

function Convert-KebabToPascalCase ([Parameter(ValueFromPipeline)] [string] $text) {
    ($text -split '-' | ForEach-Object {
        "$($_.ToCharArray()[0].ToString().ToUpper())$($_.Substring(1))"
    }) -join ''
}

function Format-XML ([xml] $xml) {
    # Configure settings for XML writer
    $xmlSettings = New-Object System.Xml.XmlWriterSettings
    $xmlSettings.Indent = $true
    $xmlSettings.CheckCharacters = $false
    $xmlSettings.ConformanceLevel = 0

    # Write XML to the configured writers
    $stringWriter = New-Object System.IO.StringWriter
    $xmlWriter = [System.XML.XmlWriter]::Create($stringWriter, $xmlSettings)
    $xml.WriteContentTo($xmlWriter)
    $xmlWriter.Flush()
    $stringWriter.Flush()

    Write-Output $stringWriter.ToString()
}

function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    [string] $name = [System.Guid]::NewGuid()
    $path = Join-Path $parent $name
    $null = New-Item $path -ItemType Directory
    return $path
}

function Convert-IconsToComponents (
        [Parameter(ValueFromPipeline)]
        [Alias("Template")]
        [string] $componentTemplate,
        [Alias("Path")]
        [string] $sourceDirectory,
        [Alias("Destination")]
        [string] $destinationDirectory) {
    # Loop through icons and create components
    Get-ChildItem -Path $sourceDirectory -Filter *.svg | 
    Foreach-Object {
        # Read and modify icon's XML
        [xml] $icon = Get-Content $_.FullName
        $icon.svg.SetAttribute('__at-sign__attributes', 'Attributes')

        # Format XML and and replace strings
        $output = (Format-XML $icon) -replace '__at-sign__', '@'
        $output = $componentTemplate -replace '{SvgContent}', $output

        # Prepare destination directory
        New-Item $destinationDirectory -ItemType Directory -Force

        # Create component in destination directory
        $componentName = "$($_.BaseName | Convert-KebabToPascalCase)Icon"
        $componentPath = Join-Path $destinationDirectory "$($componentName).razor"
        Set-Content -Path $componentPath -Value $output
    }
}

# Fetch icons from Heroicons repository
$iconsDirectory = New-TemporaryDirectory
git clone $heroiconsRepositoryUrl $iconsDirectory | Out-Null

# Generate components
$componentTemplate = Get-Content $componentTemplatePath -Raw
Convert-IconsToComponents -Template $componentTemplate -Path (Join-Path $iconsDirectory $solidIconsRemotePath) -Destination $solidIconsLocalPath
Convert-IconsToComponents -Template $componentTemplate -Path (Join-Path $iconsDirectory $outlineIconsRemotePath) -Destination $outlineIconsLocalPath
Convert-IconsToComponents -Template $componentTemplate -Path (Join-Path $iconsDirectory $miniIconsRemotePath) -Destination $miniIconsLocalPath

# Clean-up
Remove-Item $iconsDirectory -Recurse -Force
