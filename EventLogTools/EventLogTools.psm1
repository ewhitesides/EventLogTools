#Get function definition files
$Paths = @(
    "$PSScriptRoot\Public\*.ps1"
)
$ImportFiles = Get-ChildItem -Path $Paths

#Dot source the files
ForEach ($ImportFile in $ImportFiles) {
    . $ImportFile.FullName
}
