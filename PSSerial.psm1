$directorySeparator = [System.IO.Path]::DirectorySeparatorChar

# Public Dir
$publicFunctionsPath = `
    $PSScriptRoot + $directorySeparator + 'Public'

# Private Dir
#$privateFunctionsPath = `
#    $PSScriptRoot + $directorySeparator + 'Private'

# Classes Dir
$classesPath =  $PSScriptRoot + $directorySeparator + 'Classes'

# Source files
$publicFunctions = Get-ChildItem -Path $publicFunctionsPath | `
    Where-Object {$_.Extension -eq '.ps1'}
#$privateFunctions = Get-ChildItem -Path $privateFunctionsPath | `
#    Where-Object {$_.Extension -eq '.ps1'}
$classes = Get-ChildItem -Path $classesPath | `
    Where-Object {$_.Extension -eq '.ps1'}
$publicFunctions | ForEach-Object { . $_.FullName }
#$privateFunctions | ForEach-Object { . $_.FullName }
$classes | ForEach-Object { . $_.FullName }

# Export all of the public functions from this module
foreach ($func in $publicFunctions) { 
    Export-ModuleMember -Function $func.BaseName
}