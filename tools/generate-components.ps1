$componentTemplatePath = "./component-template.razor"
$libraryRootPath = "../src/Onest.HeroIcons/"
$tempPath = "../.temp/"
$solidIconsLocalPath = Join-Path $tempPath "solid/"
$outlineIconsLocalPath = Join-Path $tempPath "outline/"
$miniIconsLocalPath = Join-Path $tempPath "mini/"
$solidIconsRemotePath = "src/24/solid/*.svg"
$outlineIconsRemotePath = "src/24/outline/*.svg"
$miniIconsRemotePath = "src/20/solid/*.svg"
$heroiconsRepositoryUrl = "https://github.com/tailwindlabs/heroicons.git"

function Get-Icons {
    # Clone repository to temp directory
    $tempDirectory = New-TemporaryDirectory
    git clone $heroiconsRepositoryUrl $tempDirectory

    # Prepare directories and move icons
    New-Item -ItemType Directory -Path $tempPath
    New-Item -ItemType Directory -Path $solidIconsLocalPath
    New-Item -ItemType Directory -Path $outlineIconsLocalPath
    New-Item -ItemType Directory -Path $miniIconsLocalPath
    Get-Item (Join-Path $tempDirectory $solidIconsRemotePath) | Move-Item -Destination $solidIconsLocalPath
    Get-Item (Join-Path $tempDirectory $outlineIconsRemotePath) | Move-Item -Destination $outlineIconsLocalPath
    Get-Item (Join-Path $tempDirectory $miniIconsRemotePath) | Move-Item -Destination $miniIconsLocalPath

    Remove-Item $tempDirectory -Recurse -Force
}

function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    [string] $name = [System.Guid]::NewGuid()
    $path = Join-Path $parent $name
    $null = New-Item -ItemType Directory -Path $path
    return $path
}

function Convert-KebabToPascal ([Parameter(ValueFromPipeline)] [string] $text) {
    ($text -split '-' | ForEach-Object {
        "$($_.ToCharArray()[0].ToString().ToUpper())$($_.Substring(1))" }) -join ''
}

function Format-XML ([xml] $xml) {
    # Configure settings for XML writer
    $xmlSettings = New-Object System.Xml.XmlWriterSettings
    $xmlSettings.Indent = $true
    $xmlSettings.CheckCharacters = $false
    $xmlSettings.ConformanceLevel = 0

    # Write XML to writers
    $stringWriter = New-Object System.IO.StringWriter
    $xmlWriter = [System.XML.XmlWriter]::Create($stringWriter, $xmlSettings)
    $xml.WriteContentTo($xmlWriter)
    $xmlWriter.Flush()
    $stringWriter.Flush()

    Write-Output $stringWriter.ToString()
}

# Fetch icons from Heroicons repository
Get-Icons

# Get component template
$componentTemplate = Get-Content $componentTemplatePath

# Loop through icons and create components
Get-ChildItem -Path $tempPath -Filter *.svg -Recurse | 
Foreach-Object {
    # Read and modify icon's XML
    [xml] $icon = Get-Content -Path $_.FullName
    $icon.svg.SetAttribute('__at-sign__attributes', 'Attributes')

    # Format XML and and replace strings
    $output = (Format-XML $icon) -replace '__at-sign__', '@'
    $output = $componentTemplate -replace '{SvgContent}', $output

    # Prepare destination directory
    $destinationDirectory = Join-Path $libraryRootPath $($_.Directory.BaseName | Convert-KebabToPascal)
    New-Item -Path $destinationDirectory -ItemType Directory -Force

    # Create component in destination directory
    $componentName = "$($_.BaseName | Convert-KebabToPascal)Icon"
    $componentPath = Join-Path -Path $destinationDirectory -ChildPath "$($componentName).razor"
    Set-Content -Path $componentPath -Value $output
}

Remove-Item $tempPath -Recurse -Force