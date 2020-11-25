## Powershell Profile
## All user configurations to run before powershell launch are here.

## Note: If using CMDER, add these below config to $Env:CMDER\config\user_profile.ps1

# Conditions
# ----------

If ( (Get-Module -ListAvailable -Name 'posh-git' ) -And (Get-Module -ListAvailable -Name 'oh-my-posh') ) {
    Import-Module 'posh-git'
    Import-Module 'oh-my-posh'
    Set-Theme Agnoster
}
Else {
    function Global:prompt {
        $PromptPath = $PWD | Split-Path -Leaf
        "PS [$PromptPath] > "
    }
}


# Chocolatey profile
$ChocolateyProfile = "$Env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
If (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

# Functions
# ---------

function .. { Set-Location .. }
function assoc { CMD /C "assoc $args" }
function ftype { CMD /C "ftype $args" }
function pdf([String]$PDFFile) { Write-Output $PDFFile; Start AcroRd32.exe `"$PDFFile`" }
function vimrc { vim ~/.vimrc }
function vipro { vim $PROFILE }

# View Chrome bookmarks
function chromeBkmrks([Switch]$AllPrintAsArray) {
    function bkmrkloop($obj) {
        If ($Obj.children) {
            $Obj.children | %{ If ($_.type -eq 'url') { $_.url } }
            bkmrkloop($Obj.children)
        }
    }
    $ParsedJSON = (Get-Content "$Env:LOCALAPPDATA\Google\Chrome\User Data\Default\Bookmarks") | ConvertFrom-Json
    If ($AllPrintAsArray.IsPresent) {
        Write-Output ""
        bkmrkloop($ParsedJSON.roots.bookmark_bar)
        bkmrkloop($ParsedJSON.roots.other)
        Write-Output ""
    }
    Else {
        $Cnt = 0
        Write-Output "`n# From $($ParsedJSON.roots.bookmark_bar.name) ..."
        bkmrkloop($ParsedJSON.roots.bookmark_bar) | %{ $Cnt += 1; Write-Output "[$Cnt] $_" }
        Write-Output "`n# From $($ParsedJSON.roots.other.name) ..."
        bkmrkloop($ParsedJSON.roots.other) | %{ $Cnt += 1; Write-Output "[$Cnt] $_" }
        Write-Output ""
    }
}

# Activate Virtual Env of a Python Project
function activate([String]$ProjFolder=(Get-Location)) {
    If (Test-Path $ProjFolder'\venv') { & $ProjFolder'\venv\Scripts\Activate.ps1' }
    Else { Write-Output "Either no virtual env created OR not a python project root folder ..." }
}

# Check Url Connection
function chkconn([String]$WebSite) {
    Try {
        $HTTP_Req = [System.Net.WebRequest]::Create($WebSite)
        $HTTP_Resp = $HTTP_Req.GetResponse() | Out-Null
        Return $True
    }
    Catch [System.Net.WebException] { Return $False }
}

# Parse search string for google search
function gglSrchStr([String]$SrchFor) {
    $SrchFor = $SrchFor.Trim()
    $SrchFor = $SrchFor -Replace "\s+", " "
    $SrchFor = $SrchFor -Replace " ", "+"
    Return "https://www.google.com/search?q=$SrchFor"
}

# Open a website, do google search, open in Incognito mode, 
function web( [String]$SiteURL, [Switch]$UseFirefox, [Switch]$InCog, [Switch]$GoogleSrch ) {
    Filter IsFirefox { If ($UseFirefox.IsPresent) { Return $True } Else { Return $False } }
    Filter BrowserArg { If (IsFirefox) { Return "-private-window" } Else { Return "-incognito" } }

    # Default is Chrome Browser
    $BrowserExePath = 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe'
    If (IsFirefox) { $BrowserExePath = 'C:\Program Files\Mozilla Firefox\firefox.exe' }
    If ($GoogleSrch.IsPresent) { $SiteURL = (gglSrchStr $SiteURL) }
    If ($InCog.IsPresent) {
        Start -FilePath $BrowserExePath -ArgumentList (BrowserArg), $(
                If (Test-Path $SiteURL) { 'file:///' + (ls $SiteURL).FullName }
                Else { $SiteURL }
        )
    }
    Else { Start -FilePath $BrowserExePath -ArgumentList $SiteURL }
}

# UTF conversion
function U {
    Param([Int]$Code)
    If ((0 -le $Code) -and ($Code -le 0xFFFF)) { return [char] $Code }
    If ((0x10000 -le $Code) -and ($Code -le 0x10FFFF)) { return [char]::ConvertFromUtf32($Code) }
    throw "Invalid character code $Code"
}

# Upload file(s) to git repo
function upload {
    Param(
        [Parameter(Position=0)][String]$file,
        [Parameter(Mandatory=$True, Position=1)][String]$msg
    )
    Write-Output "Adding to Changes ...`n"
    If ( [String]::IsNullOrEmpty($file) ) { git add . }
    Else { git add $file }
    Write-Output "Commiting ...`n"
    git commit -m $msg
    Write-Output "Pushing to Github ..."
    git push origin master
}

# Do a vim diff
function vdiff([String]$f1, [String]$f2) {
    If ( (Test-Path "C:\cygwin64") -Or (Test-Path "C:\cygwin") ) {
        "/cygdrive/c/cygwin64/bin/vimdiff `$1 `$2" | Set-Content .\tmp.sh
        (dos2unix.exe tmp.sh) 2>&1 | Out-Null
        & bash 'tmp.sh' $f1 $f2
        Remove-Item .\tmp.sh -Force -ErrorAction SilentlyContinue
    }
    Else { Write-Output "Cygwin not found!! [Modify your PSH Profile if Cygwin is installed elsewhere]" }
}

# View CMDER profile.
# Usually is '$Env:CMDER_ROOT\config\user_profile.ps1' and '$Env:CMDER_ROOT\vendor\profile.ps1'
function cmdrpro([Switch]$vp) {
    If ($vp.IsPresent) { vim $Env:CMDER_ROOT\vendor\profile.ps1 }
    Else { vim $Env:CMDER_ROOT\config\user_profile.ps1 }
}

# Aliases
# -------

# Alias to notepad++
If (Test-Path "${Env:ProgramFiles(x86)}\Notepad++") {
    New-Alias -Name np -Value "${Env:ProgramFiles(x86)}\Notepad++\notepad++.exe"
}

# Alias to Beyand Compare 
If (Test-Path 'C:\Program Files\Beyond Compare 4\BCompare.exe') {
    New-Alias -Name 'bc' -Value 'C:\Program Files\Beyond Compare 4\BCompare.exe' -Scope 'Global'
}

# Aliases to unix find and tree commands
If ( (Test-Path "C:\cygwin64") -Or (Test-Path "C:\cygwin") ) {
    New-Alias -Name 'lfind' -Value 'C:\cygwin64\bin\find.exe' -Scope 'Global'
    New-Alias -Name 'ltree' -Value 'C:\cygwin64\bin\tree.exe' -Scope 'Global'
}

