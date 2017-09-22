﻿param([String]$SrcRoot="undefined")

#to Run the script simply run the following commnand from a PowerShell prompt
#Here is a PowerShell script to process the file from the TouchDown project

#What would be the standard steps to enable check in process
#  -Sync the Localized File on the machine
#  -GIT reset –hard reset
#  -GIT pull
#  -Create a Temp loc branch
#  -Set the Flag (ChangesAreDetected = false)
#  -Call TD
#  -Extract the ZIP file
#  -Map the extracted file to the Local file
#  -Compare the localized File with File in the Repo, if those files are different then run the command sd add
#  -Set the Flag (ChangesAreDetected = True)
#  -Run a Git push (Integrate the TempLocBranch to your working branch)

#Let generate the Command Line to pull our the Touch Down file
#Here are the variables needed
#  $absoluteFilePath
#  $outFilePath
#  $relativeFilePath
#  $teamId  (can be defined as a Global Variable)
#At first it will place those either in a CSV file or XML file
#You can provide the $Srcroot from the command line. If you add those variable in your path from the script, those will be automatically replaced
#The Language can also specified so that you have a very flexible way of binplacing the Localized file.

# we need to build a command line that is like this:

#Here is an example of Command line
#Invoke-RestMethod -Uri "http://tdbuild/api/teams/$teamId/LocalizableFiles" -Method Put -UseDefaultCredentials -ContentType "multipart/form-data; boundary=$boundary" -Body $body -OutFile $outFilePath

$CultureSettingFile= "mobile-center-cultures.csv"
$ProjectInfo = "mobile-center-sdks-loc-file-list.csv"

$Guid = [GUID]::NewGuid()
$TempLocBranch = "TouchDownCheckin_" +  $Guid
$repoPath = $SrcRoot
$LogFile = "C:\TouchDown\TDCheckin\log.txt"
$DefaultRepoBranch = "master"
$teamId = "272" #ID for iOS
$git = "git"

Function ProcessStart($AppToRun,$Argument,$WorkingDir)
{
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $AppToRun
    $pinfo.Arguments = $Argument
    $pinfo.WorkingDirectory = $WorkingDir
    $pinfo.CreateNoWindow = $True
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false

    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()

    $output = $p.StandardOutput.ReadToEnd()
    $output += $p.StandardError.ReadToEnd()

    write-host $output
}

Function InitializeRepoForCheckin
{
    $Argument = "checkout " + $DefaultRepoBranch 
    ProcessStart $git $Argument $repoPath

    $Argument = "reset --hard HEAD"
    ProcessStart $git $Argument $repoPath
    #Start-Process $git $Argument -WorkingDirectory $repoPath -NoNewWindow

    $Argument = "pull"
    ProcessStart $git $Argument $repoPath
    #Start-Process $git $Argument -WorkingDirectory $repoPath -NoNewWindow

    $Argument = "checkout -b" + $TempLocBranch
    ProcessStart $git $Argument $repoPath
    #Start-Process $git $Argument -WorkingDirectory $repoPath -NoNewWindow -redirectstandardoutput $logfile 
}

Function CheckinFilesIntoRepo
{
    #Commit the changes
    $Argument = 'commit  -m "Latest localized files from touchdown"'
    ProcessStart $git $Argument $repoPath

    #Push the Changes to the  git server you still need to merge the changes
    $Argument = "push -u origin " + $TempLocBranch
    ProcessStart $git $Argument $repoPath
}

Class Cl_Culture 
{
    [String]$LCID
    [String]$LSBUILD
    [string]$Culture

    Cl_Culture ([string]$LCID,$LSBUILD,$Culture)
    {
        $this.LCID =$LCID
        $this.LSBUILD = $LSBUILD
        $this.Culture = $Culture
    }
}

#Unzip a file
Add-Type -AssemblyName System.IO.Compression.FileSystem
Function Unzip ($zipfile,$outpath)
{
    write-Host "We are unzipping the zip file $zipfile to $outpath"

    #Remove the content of the outpath folder if it exists
    if ((Test-Path -Path $outpath) -and $outpath.Contains("Unzip"))
    {
        write-host "Deleting the file"
        Remove-Item -Recurse -Force $outpath
    }

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

Function GetCulture($CultureFile,$CultureToSearch)
{
    $Cultures = Import-CSV $CultureFile 

    ForEach ($culture in $Cultures)
    {
        $LCID =$culture.LCID
        $LSBUILDCULTURE =$culture.LSBUILDCULTURE
        $CULTURE =$culture.Culture

        if ($CultureToSearch -eq $LSBUILDCULTURE)
        {
            $OCulture = [Cl_Culture]::new($LCID,$LSBUILDCULTURE,$Culture)
            write-host $OCulture.LSBUILD
            Return $OCulture
        }
    }
}

Function TouchDownTransaction ($absoluteFilePath,$outFilePath,$relativeFilePath,$teamId,$LanguageSet)
{
    $filePath = @{ FilePath = $relativeFilePath }
    $filePathJson = ConvertTo-Json $filePath -Compress

    # convert file into an octet-stream
    $fileBinary = [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetString((Get-Content -Encoding Byte -Path $absoluteFilePath))

    # generate form-data body
    $boundary = "tdbuildFormBoundary"

    #Formatting is weird in script to keep correct format for output?
    $body = @"
--$boundary
Content-Disposition: form-data; name="application/json"
Content-Type: application/json

$filePathJson
--$boundary
Content-Disposition: form-data; name="resources"; filename="resources"
Content-Type: application/octet-stream

$fileBinary
--$boundary--
"@

    Invoke-RestMethod -Uri "http://tdbuild/api/teams/$teamId/LocalizableFiles" -Method Put -UseDefaultCredentials -ContentType "multipart/form-data; boundary=$boundary" -Body $body -OutFile $outFilePath
}

Function binplace ($UnzipFileTo,$relativeFilePath,$TargetPath,$LanguageSet)
{
    $Langs = $LanguageSet.split(";")
    
    write-host "the culture file is: $CultureFile"

    foreach($Language in $Langs)
    {
        $OCulture = GetCulture $CultureSettingFile $Language
        $Culture = $OCulture.Culture
        write-host "OCulture: $OCulture"

        $LocalizedFile = $UnzipFileTo + "\" + $OCulture.Lsbuild  + $relativeFilePath
        $TargetPathDir = $TargetPath.Substring(0,$TargetPath.LastIndexOf("\"))

        write-host "Loc File:   $LocalizedFile"
        write-host "TargetPath: $TargetPath"
        write-host "Copying Loc file to TargetPath"

        if(!(Test-Path -Path $TargetPathDir )){
            New-Item $TargetPathDir -type directory
        }

        Copy-Item $LocalizedFile $TargetPath
    }
}

Function AddFiletoRepo ($TargetPath,$LanguageSet)
{
    $Langs = $LanguageSet.split(";")

    foreach($Language in $Langs)
    {
        $OCulture = GetCulture $CultureSettingFile $Language

        #We pull out here the culture that might be used during the string expansion.
        $Culture = $OCulture.Culture
        $Argument = "add " + $TargetPath

        write-host $Argument

        #Start-Process $git $Argument -WorkingDirectory $repoPath
        ProcessStart $git $Argument $repoPath
    }
}

Function RefreshTDFiles
{
    InitializeRepoForCheckin

    $Files = Import-CSV $ProjectInfo 

    Foreach($File in $Files)
    {
        write-host "Start processing Files"

        $absoluteFilePath = $File.absoluteFilePath
        $outFilePath      = $File.outFilePath
        $relativeFilePath = $File.relativeFilePath
        $TargetPath       = $File.TargetPath
        $LanguageSet      = $File.LanguageSet

        $outFilePath      = $ExecutionContext.InvokeCommand.ExpandString($outFilePath)
        $absoluteFilePath = $ExecutionContext.InvokeCommand.ExpandString($absoluteFilePath)
        $TargetPath       = $ExecutionContext.InvokeCommand.ExpandString($TargetPath)

        write-host "-----TOUCHDOWN TRANSACTION-----"
        TouchDownTransaction $absoluteFilePath $outFilePath $relativeFilePath $teamId $LanguageSet

        $UnzipFolderLocation = $SrcRoot + "\Localization\Unzip"

        Unzip $outFilePath $UnzipFolderLocation

        binplace $UnzipFolderLocation $relativeFilePath $TargetPath $LanguageSet

        AddFiletoRepo $TargetPath $LanguageSet
    }

    CheckinFilesIntoRepo
}

RefreshTDFiles