[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$PullRequestUrl,

    [Parameter(Mandatory = $false)]
    [string]$Organization,

    [Parameter(Mandatory = $false)]
    [string]$Project,

    [Parameter(Mandatory = $false)]
    [string]$RepositoryId,

    [Parameter(Mandatory = $false)]
    [int]$PullRequestId,

    [Parameter(Mandatory = $false)]
    [string]$Pat = $env:AZURE_DEVOPS_PAT,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeRawThreads
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-PullRequestParts {
    param([string]$Url)

    if ([string]::IsNullOrWhiteSpace($Url)) {
        return $null
    }

    $pattern = '^https://dev\.azure\.com/(?<organization>[^/]+)/(?<project>[^/]+)/_git/(?<repository>[^/]+)/pullrequest/(?<pullRequestId>\d+)(\?.*)?$'
    $match = [regex]::Match($Url, $pattern)
    if (-not $match.Success) {
        throw 'Invalid Azure DevOps pull request URL.'
    }

    return [PSCustomObject]@{
        Organization  = $match.Groups['organization'].Value
        Project       = $match.Groups['project'].Value
        RepositoryId  = $match.Groups['repository'].Value
        PullRequestId = [int]$match.Groups['pullRequestId'].Value
    }
}

function New-BasicAuthHeader {
    param([string]$Token)

    if ([string]::IsNullOrWhiteSpace($Token)) {
        throw 'PAT missing. Set AZURE_DEVOPS_PAT or pass -Pat.'
    }

    $bytes = [System.Text.Encoding]::ASCII.GetBytes(":$Token")
    $encoded = [Convert]::ToBase64String($bytes)
    return @{ Authorization = "Basic $encoded"; Accept = 'application/json' }
}

function Get-ThreadSide {
    param($ThreadContext)

    if ($null -eq $ThreadContext) { return 'general' }
    $hasRight = ($null -ne $ThreadContext.rightFileStart) -or ($null -ne $ThreadContext.rightFileEnd)
    $hasLeft = ($null -ne $ThreadContext.leftFileStart) -or ($null -ne $ThreadContext.leftFileEnd)
    if ($hasRight) { return 'right' }
    if ($hasLeft) { return 'left' }
    return 'general'
}

function Get-ValueOrNull {
    param($Object, [string]$Name)

    if ($null -eq $Object) { return $null }
    if ($null -ne $Object.PSObject.Properties[$Name]) { return $Object.$Name }
    return $null
}

$parts = Resolve-PullRequestParts -Url $PullRequestUrl
if ($null -ne $parts) {
    if ([string]::IsNullOrWhiteSpace($Organization)) { $Organization = $parts.Organization }
    if ([string]::IsNullOrWhiteSpace($Project)) { $Project = $parts.Project }
    if ([string]::IsNullOrWhiteSpace($RepositoryId)) { $RepositoryId = $parts.RepositoryId }
    if (-not $PullRequestId) { $PullRequestId = $parts.PullRequestId }
}

if ([string]::IsNullOrWhiteSpace($Organization) -or [string]::IsNullOrWhiteSpace($Project) -or [string]::IsNullOrWhiteSpace($RepositoryId) -or -not $PullRequestId) {
    throw 'Missing Azure DevOps pull request identifiers.'
}

$headers = New-BasicAuthHeader -Token $Pat
$uri = "https://dev.azure.com/$Organization/$Project/_apis/git/repositories/$RepositoryId/pullRequests/$PullRequestId/threads?api-version=7.1"
$response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
$threads = if ($null -ne $response.value) { @($response.value) } else { @() }
$comments = New-Object System.Collections.Generic.List[object]

foreach ($thread in $threads) {
    $context = $thread.threadContext
    $side = Get-ThreadSide -ThreadContext $context
    $start = $null
    $end = $null
    if ($side -eq 'right') {
        $start = Get-ValueOrNull -Object $context -Name 'rightFileStart'
        $end = Get-ValueOrNull -Object $context -Name 'rightFileEnd'
    }
    elseif ($side -eq 'left') {
        $start = Get-ValueOrNull -Object $context -Name 'leftFileStart'
        $end = Get-ValueOrNull -Object $context -Name 'leftFileEnd'
    }

    foreach ($comment in @($thread.comments)) {
        $comments.Add([PSCustomObject]@{
            thread_id = $thread.id
            comment_id = $comment.id
            parent_comment_id = $comment.parentCommentId
            author = if ($null -ne $comment.author) { $comment.author.displayName } else { $null }
            content = $comment.content
            file_path = Get-ValueOrNull -Object $context -Name 'filePath'
            side = $side
            start_line = Get-ValueOrNull -Object $start -Name 'line'
            end_line = Get-ValueOrNull -Object $end -Name 'line'
            start_offset = Get-ValueOrNull -Object $start -Name 'offset'
            end_offset = Get-ValueOrNull -Object $end -Name 'offset'
            thread_status = Get-ValueOrNull -Object $thread -Name 'status'
            thread_is_deleted = Get-ValueOrNull -Object $thread -Name 'isDeleted'
            comment_is_deleted = Get-ValueOrNull -Object $comment -Name 'isDeleted'
            published_date = Get-ValueOrNull -Object $comment -Name 'publishedDate'
            last_updated_date = Get-ValueOrNull -Object $comment -Name 'lastUpdatedDate'
        })
    }
}

$result = [PSCustomObject]@{
    organization = $Organization
    project = $Project
    repository_id = $RepositoryId
    pull_request_id = $PullRequestId
    thread_count = @($threads).Count
    comment_count = @($comments).Count
    comments = @($comments)
    raw_threads = if ($IncludeRawThreads) { $threads } else { $null }
}

$result | ConvertTo-Json -Depth 100
