#requires -Modules MVP

$SubscriptionKey = 'aaabbbbcdbbcjdbjkcdjk8129310i0asd' 
$ContribuitionLimitGet = 200
$StartCicleDate = "2018-04-01"
$GoogleApiId = "sdklansdjhausfaksfnklasjansjvnajkscnjasjc"

Set-MVPConfiguration -SubscriptionKey $SubscriptionKey
#Function Get Views in Youtube Videos
function Get-YoutubeViewCount {
    Param(
        # Parameter help description
        [Parameter(Mandatory = $true)]
        [System.String]$GoogleApiKey,
        [Parameter(Mandatory = $true)]
        [System.String]$VideoId
    )
    PROCESS{
        $RestCall = @{
            Uri = 'https://www.googleapis.com/youtube/v3/videos?id={0}&key={1}&part=snippet,contentDetails,statistics,status' -f $VideoId, $GoogleApiKey
        }
        $Result = Invoke-RestMethod @RestCall
    
        Write-Output -InputObject $Result.items.statistics.viewCount
    }
}

$Contributions = Get-MVPContribution -Limit $ContribuitionLimitGet

foreach ($contribs in $Contributions) {
    if ($contribs.ContributionTypeName -eq "Video/Webcast/Podcast") {
        $contributionId = $contribs.ContributionId 
        $youtubeUrl = $contribs.ReferenceUrl 
       
        if ($contribs.ReferenceUrl.Contains('youtu')) {
            $videoId = $youtubeUrl.Replace('https://youtu.be/', '').Replace('https://www.youtube.com/watch?v=', '')
            $ContribDate = $contribs.StartDate           
            
            if ([datetime]$ContribDate -ge [datetime]$StartCicleDate) {

                $views = Get-YoutubeViewCount -GoogleApiKey $GoogleApiKey -VideoId $VideoId
                
                try{
                    Set-MVPContribution -ContributionID $contributionId -AnnualReach $views -ErrorAction 'Stop'
                }
                catch{
                    Write-Error -Message $Error[0].exception.Message
                }
                Write-Host "Updating Contribution: $($contributionId) - AnnualReach: $($views) - $($ContribDate)"
                #Alert - Sometimes the MVP API returns error 500.
                Start-Sleep -s 15
            }
            else {
                Write-Warning "Date Out Of Range - Contribution: $($contributionId) - Not Updated - $($ContribDate)"
            }   
        }
    }
}
