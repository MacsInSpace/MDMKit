function New-MosyleClass {
    <#
    .SYNOPSIS
        Creates or saves a class in Mosyle (POST /classes, operation "save").
    .DESCRIPTION
        Returns the class UUID from the response. -Student and -Coordinator take arrays
        of user IDs. -Platform is ios (default) or mac.
    .EXAMPLE
        New-MosyleClass -Id sci8 -CourseName Science -ClassName '8A Science' -Location 'Main Campus' -Teacher t.smith
    .EXAMPLE
        New-MosyleClass -Id sci8 -CourseName Science -ClassName '8A Science' -Location Main -Teacher t.smith -Student s1, s2
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string] $Id,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('course_name')]
        [string] $CourseName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('class_name')]
        [string] $ClassName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string] $Location,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('idteacher')]
        [string] $Teacher,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]] $Student,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]] $Coordinator,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Room,

        [ValidateSet('ios', 'mac')]
        [string] $Platform = 'ios',

        [PSTypeName('MosyleKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-MosyleSession -Session $Session
        $elements = [System.Collections.Generic.List[object]]::new()
    }

    process {
        $element = [ordered]@{
            operation   = 'save'
            id          = $Id
            course_name = $CourseName
            class_name  = $ClassName
            location    = $Location
            idteacher   = $Teacher
            platform    = $Platform
        }
        if ($null -ne $Student -and $Student.Count -gt 0) { $element['students'] = @($Student) }
        if ($null -ne $Coordinator -and $Coordinator.Count -gt 0) { $element['coordinators'] = @($Coordinator) }
        if ($Room) { $element['room'] = $Room }
        [void]$elements.Add($element)
    }

    end {
        if ($elements.Count -eq 0) { return }
        if ($PSCmdlet.ShouldProcess("$($elements.Count) class(es)", 'Save Mosyle class')) {
            $response = Invoke-MosyleRequest -Session $resolved -Endpoint 'classes' -Body @{ elements = @($elements) }
            Select-MosyleResult -Response $response -Property 'uuid', 'elements'
        }
    }
}
