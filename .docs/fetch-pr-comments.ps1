
Save New Duplicate & Edit Just Text Twitter
<#
.SYNOPSIS
Fetch Azure DevOps pull request comment threads and flatten them into a
coding-agent-friendly structure with file path and line information.

.DESCRIPTION
- Reads PR threads from Azure DevOps REST API
- Extracts thread comments
- Includes file path and line range when the thread is file-anchored
- Emits JSON by default

.PARAMETER Organization
Azure DevOps organization name

.PARAMETER Project
Azure DevOps project name

.PARAMETER RepositoryId
Repository ID or repository name

.PARAMETER PullRequestId
Pull request ID

.PARAMETER Pat
Azure DevOps Personal Access Token.
If omitted, the script tries $env:AZDO_PAT.

.PARAMETER OutputPath
Optional path to write the flattened JSON result

.PARAMETER IncludeRawThreads
Also include the raw thread payload in the output object

.EXAMPLE
./Get-AdoPrComments.ps1 `
  -Organization "myorg" `
  -Project "myproject" `
  -RepositoryId "myrepo" `
  -PullRequestId 123 `
  -Pat $env:AZDO_PAT

.EXAMPLE
./Get-AdoPrComments.ps1 `
  -Organization "myorg" `
  -Project "myproject" `
  -RepositoryId "myrepo" `
  -PullRequestId 123 `
  -OutputPath "./pr-comments.json"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Organization,

    [Parameter(Mandatory = $true)]
    [string]$Project,

    [Parameter(Mandatory = $true)]
    [string]$RepositoryId,

    [Parameter(Mandatory = $true)]
    [int]$PullRequestId,

    [Parameter(Mandatory = $false)]
    [string]$Pat = $env:AZDO_PAT,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeRawThreads
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-BasicAuthHeader {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Token
    )

    if ([string]::IsNullOrWhiteSpace($Token)) {
        throw "PAT missing. Pass -Pat or set AZDO_PAT."
    }

    $bytes = [System.Text.Encoding]::ASCII.GetBytes(":$Token")
    $encoded = [Convert]::ToBase64String($bytes)

    return @{
        Authorization = "Basic $encoded"
        Accept        = "application/json"
    }
}

function Invoke-AdoGet {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,

        [Parameter(Mandatory = $true)]
        [hashtable]$Headers
    )

    Write-Verbose "GET $Uri"
    return Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers
}

function Get-PrThreads {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        [Parameter(Mandatory = $true)]
        [string]$Project,

        [Parameter(Mandatory = $true)]
        [string]$RepositoryId,

        [Parameter(Mandatory = $true)]
        [int]$PullRequestId,

        [Parameter(Mandatory = $true)]
        [hashtable]$Headers
    )

    $uri = "https://dev.azure.com/$Organization/$Project/_apis/git/repositories/$RepositoryId/pullRequests/$PullRequestId/threads?api-version=7.1"
    $response = Invoke-AdoGet -Uri $uri -Headers $Headers

    if ($null -eq $response.value) {
        return @()
    }

    return @($response.value)
}

function Get-LineValue {
    param(
        [Parameter(Mandatory = $false)]
        $Position
    )

    if ($null -eq $Position) {
        return $null
    }

    if ($null -ne $Position.PSObject.Properties['line']) {
        return $Position.line
    }

    return $null
}

function Get-OffsetValue {
    param(
        [Parameter(Mandatory = $false)]
        $Position
    )

    if ($null -eq $Position) {
        return $null
    }

    if ($null -ne $Position.PSObject.Properties['offset']) {
        return $Position.offset
    }

    return $null
}

function Get-ThreadSide {
    param(
        [Parameter(Mandatory = $false)]
        $ThreadContext
    )

    if ($null -eq $ThreadContext) {
        return "general"
    }

    $properties = $ThreadContext.PSObject.Properties

    $hasRight =
        ($null -ne $properties['rightFileStart'] -and $null -ne $ThreadContext.rightFileStart) -or
        ($null -ne $properties['rightFileEnd'] -and $null -ne $ThreadContext.rightFileEnd)

    $hasLeft =
        ($null -ne $properties['leftFileStart'] -and $null -ne $ThreadContext.leftFileStart) -or
        ($null -ne $properties['leftFileEnd'] -and $null -ne $ThreadContext.leftFileEnd)

    if ($hasRight) {
        return "right"
    }

    if ($hasLeft) {
        return "left"
    }

    return "general"
}

function Convert-ThreadsToFlattenedComments {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Threads
    )

    $items = New-Object System.Collections.Generic.List[object]

    foreach ($thread in $Threads) {
        $threadProperties = $thread.PSObject.Properties
        $threadId = $thread.id
        $threadContext = $thread.threadContext
        $threadStatus = if ($null -ne $threadProperties['status']) { $thread.status } else { $null }
        $threadIsDeleted = if ($null -ne $threadProperties['isDeleted']) { $thread.isDeleted } else { $null }

        $filePath = $null
        $side = "general"

        $startLine = $null
        $endLine = $null
        $startOffset = $null
        $endOffset = $null

        if ($null -ne $threadContext) {
            if ($null -ne $threadContext.PSObject.Properties['filePath']) {
                $filePath = $threadContext.filePath
            }

            $side = Get-ThreadSide -ThreadContext $threadContext

            $startPosition = $null
            $endPosition = $null

            if ($side -eq "right") {
                if ($null -ne $threadContext.PSObject.Properties['rightFileStart']) {
                $startPosition = $threadContext.rightFileStart
                }
                if ($null -ne $threadContext.PSObject.Properties['rightFileEnd']) {
                $endPosition = $threadContext.rightFileEnd
            }
            }
            elseif ($side -eq "left") {
                if ($null -ne $threadContext.PSObject.Properties['leftFileStart']) {
                $startPosition = $threadContext.leftFileStart
                }
                if ($null -ne $threadContext.PSObject.Properties['leftFileEnd']) {
                $endPosition = $threadContext.leftFileEnd
            }
            }

            $startLine = Get-LineValue -Position $startPosition
            $endLine = Get-LineValue -Position $endPosition
            $startOffset = Get-OffsetValue -Position $startPosition
            $endOffset = Get-OffsetValue -Position $endPosition
        }

        $comments = @()
        if ($null -ne $threadProperties['comments'] -and $null -ne $thread.comments) {
            $comments = @($thread.comments)
        }

        foreach ($comment in $comments) {
            $commentProperties = $comment.PSObject.Properties
            $author = if ($null -ne $comment.author) { $comment.author.displayName } else { $null }

            $items.Add([PSCustomObject]@{
                threadId          = $threadId
                commentId         = $comment.id
                parentCommentId   = $comment.parentCommentId
                author            = $author
                content           = $comment.content
                commentType       = if ($null -ne $commentProperties['commentType']) { $comment.commentType } else { $null }
                isDeleted         = if ($null -ne $commentProperties['isDeleted']) { $comment.isDeleted } else { $null }
                publishedDate     = if ($null -ne $commentProperties['publishedDate']) { $comment.publishedDate } else { $null }
                lastUpdatedDate   = if ($null -ne $commentProperties['lastUpdatedDate']) { $comment.lastUpdatedDate } else { $null }
                filePath          = $filePath
                side              = $side
                startLine         = $startLine
                endLine           = $endLine
                startOffset       = $startOffset
                endOffset         = $endOffset
                threadStatus      = $threadStatus
                threadIsDeleted   = $threadIsDeleted
            })
        }
    }

    return @($items)
}

try {
    $headers = New-BasicAuthHeader -Token $Pat
    $threads = Get-PrThreads `
        -Organization $Organization `
        -Project $Project `
        -RepositoryId $RepositoryId `
        -PullRequestId $PullRequestId `
        -Headers $headers

    $flattenedComments = Convert-ThreadsToFlattenedComments -Threads $threads

    $result = [PSCustomObject]@{
        organization    = $Organization
        project         = $Project
        repositoryId    = $RepositoryId
        pullRequestId   = $PullRequestId
        threadCount     = @($threads).Count
        commentCount    = @($flattenedComments).Count
        comments        = $flattenedComments
        rawThreads      = if ($IncludeRawThreads) { $threads } else { $null }
    }

    $json = $result | ConvertTo-Json -Depth 100

    if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
        $parent = Split-Path -Parent $OutputPath
        if (-not [string]::IsNullOrWhiteSpace($parent) -and -not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }

        Set-Content -LiteralPath $OutputPath -Value $json -Encoding UTF8
        Write-Host "Wrote output to: $OutputPath"
    }
    else {
        $json
    }
}
catch {
    Write-Error $_
    exit 1
}
