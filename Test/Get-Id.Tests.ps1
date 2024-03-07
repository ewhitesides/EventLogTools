#Requires -Modules @{ModuleName='Pester';ModuleVersion='5.5.0'}

Describe 'Get-Id' -Tag 'Unit' {

    BeforeAll {
        . "$PSScriptRoot/../EventLogTools/Private/Get-Id.ps1"
    }

    Context "When providing a message and default hash name" {
        It "Should return a valid ID" {
            $message = "Hello, World!"
            $expectedId = "10116"
            $result = Get-Id -Message $message
            $result | Should -Be $expectedId
        }
    }

    Context "When providing a message and specific hash name" {
        It "Should return a valid ID" {
            $message = "Hello, World!"
            $hashName = "SHA256"
            $expectedId = "22325"
            $result = Get-Id -Message $message -HashName $hashName
            $result | Should -Be $expectedId
        }
    }
}
