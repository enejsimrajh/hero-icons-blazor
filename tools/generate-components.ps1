function ConvertCase-KebabToPascal ([Parameter(ValueFromPipeline)] [string] $text) {
    ($text -split '-' | ForEach-Object {
        "$($_.ToCharArray()[0].ToString().ToUpper())$($_.Substring(1))" }) -join ''
}

function Format-XML ([xml]$xml) {    
    $xmlSettings = New-Object System.Xml.XmlWriterSettings
    $xmlSettings.Indent = $true
    $xmlSettings.CheckCharacters = $false
    $xmlSettings.ConformanceLevel = 0

    $stringWriter = New-Object System.IO.StringWriter
    $xmlWriter = [System.XML.XmlWriter]::Create($stringWriter, $xmlSettings)
    $xml.WriteContentTo($xmlWriter)
    $xmlWriter.Flush()
    $stringWriter.Flush()

    Write-Output $stringWriter.ToString()
}

# Get component template
$template = Get-Content -Path "./component-template.razor"

Get-ChildItem -Path "../icons" -Filter *.svg -Recurse | 
Foreach-Object {
    # Create destination directory
    $destinationDir = "../src/Onest.HeroIcons/$($_.Directory.BaseName | ConvertCase-KebabToPascal)/"
    New-Item -Path $destinationDir -ItemType Directory -Force

    # Read and modify icon xml
    [xml]$svgXml = Get-Content -Path $_.FullName
    $svgXml.svg.SetAttribute('__at-sign__attributes', 'Attributes')
    $svg = (Format-XML $svgXml) -replace '__at-sign__', '@'

    # Create component
    $output = $template -replace '{SvgContent}', $svg
    $fileName = "$($_.BaseName | ConvertCase-KebabToPascal)Icon.razor"
    $destinationFile = Join-Path -Path $destinationDir -ChildPath $fileName
    Set-Content -Path $destinationFile -Value $output
}
