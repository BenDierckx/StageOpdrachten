$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Opdracht1Refactored" {
    #Not valid anymore
    <#context "without input parameters" {
        $result = GenerateAccount
        It "returns 6 chars long account" {
            $result.Length | Should be 6
        }
        It "returns beckwb" {
            $result | should be "beckwb"
        }
    }#>

    context "With input parameters -firstName Wim, -lastName Beck" {
        $result = GenerateAccount -firstName Wim -lastName Beck
        It "Returns 6 chars long account" {
            $result.Length | Should be 6
        }
        It "Returns beckwb" {
            $result | should be "beckwb"
        }
    }

    context "With input parameters -firstName Wouter, -lastName Landuyt" {
        $result = GenerateAccount -firstName Wouter -lastName Landuyt
        It "Returns 6 chars long account" {
            $result.Length | Should be 6
        }
        It "Returns landuw" {
            $result | should be "landuw"
        }
    }

    context "With input parameters -firstName Joren, -lastName Van Camp" {
        $result = GenerateAccount -firstName Joren -lastName "Van Camp"
        It "Returns 6 chars long account" {
            $result.Length | Should be 6
        }
        It "Returns campjc" {
            $result | should be "campjc"
        }
    }
}


