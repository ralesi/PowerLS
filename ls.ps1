<#
  .Synopsis
  Powershell unix-like ls
  Originally Written by Jesse Jurman (JRJurman)
  Current Implementation by Rich Alesi (ralesi)

  .Description
  A colorful ls

  .Parameter Lspath
  The path to show

  .Example
  # List the current directory
  poshls

  .Example
  # List the parent directory
  poshls ../
#>
function Get-FileListing {
  [CmdletBinding()]
  param(
    [Parameter(Position=0)]
    [string]$lspath = ".",
    [Alias('a')]
    [switch]
    $HiddenFiles = $null,
    [Alias('S')]
    [switch]
    $SortSize = $null,
    [Alias('X')]
    [switch]
    $SortExtension = $null,
    [Alias('t')]
    [switch]
    $SortTime = $null,
    [Alias('U')]
    [switch]
    $NoSort = $null,
    [Alias('l')]
    [switch]
    $LongListing = $null,
    [Alias('la','al')]
    [switch]
    $LongAll = $null
  )

  # for testing
  # write-host ($PSCmdlet.MyInvocation | out-string)

  if ($LongAll) {
    $LongListing = $true
    $HiddenFiles = $true
  }

  # get the console buffersize
  $BufferWidth = (Get-Host).ui.rawui.buffersize.width

  # get all the files and folders
  if ($HiddenFiles) {
    $Childs = @(Get-ChildItem $lspath)
  }
  else {
    $Childs = @(Get-ChildItem $lspath | Where-Object {$_.Name -notmatch "^\..*$"})
  }

  if ($SortSize) {
    $Childs = @($Childs | Sort-Object -property length)
  } elseif ($SortTime) {
    $Childs = @($Childs | Sort-Object -property LastWriteTime)
  } elseif ($SortExtension) {
    $Childs = @($Childs | Sort-Object -property Extension)
  } elseif (-not $NoSort){
    $Childs = @($Childs | Sort-Object)
  } else {}

  # get the longest string and get the length
  $LargestLength = ($Childs | % { $_.Name.Length } | Measure-Object -Maximum).Maximum

  # keep track of how long our line is so far
  $CurrentColumn = 0

  # for every element, print the line

  $jlist = $null
  if ($LongListing) {
    Write-Host ("total: {0:n2}K" -f $($($Childs | Where-Object -property length | Measure-Object -property length -sum).sum / 1KB))
    $jlist = junctions
  }


  if ($PSCmdlet.MyInvocation.PipelineLength -gt 1) {

    return $Childs

  } else {

    foreach ($e in $Childs) {

      if ($LongListing) {
        write-host ("{0,-6}  {1,22} {2,16} " -f $e.mode,`
          ([String]::Format("{0,10} {1,8}",`
          $e.LastWriteTime.ToString("d"),`
          $e.LastWriteTime.ToString("HH:mm:ss"))),`
          $(hfs($e))) -nonewline
      }
      $Name = $e.Name

      $target = $null

      foreach ($j in $jlist) {
        if ($j[0] -eq $e.Name) {
          $target = $j[1]
        }
      }
      # determine color we should be printing
      if (($e.Attributes -band [IO.FileAttributes]::ReparsePoint) -and ($e.PSIsContainer)) {
        # dir links
        write-host "$Name" -nonewline -foregroundcolor cyan
        write-host "@  " -nonewline -foregroundcolor white
        if ($target) {
          write-host "-> $target" -nonewline -foregroundcolor yellow
        }
      } elseif ($e.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        #links
        write-host "$Name" -nonewline -foregroundcolor darkgreen
        write-host "@  " -nonewline -foregroundcolor white
        if ($target) {
          write-host "-> $target" -nonewline -foregroundcolor yellow
        }
      } elseif (($Name -match "^\..*$") -and ($e.PSIsContainer)) {
        # hidden folders
        write-host "$Name" -nonewline -foregroundcolor darkcyan
        write-host "/  " -nonewline -foregroundcolor white
      } elseif ($e.PSIsContainer) {
        #folders
        write-host "$Name" -nonewline -foregroundcolor blue
        write-host "/  " -nonewline -foregroundcolor white
      } elseif ($Name -match "^\..*$") {
        #hidden files
        write-host "$Name   " -nonewline -foregroundcolor darkgray
      } elseif ($Name -match "\.[^\.]*") {
        #normal files
        write-host "$Name   " -nonewline -foregroundcolor green
      } else { #others...
        write-host "$Name   " -nonewline -foregroundcolor white
      }
      if ($LongListing) {
        write-host ""
      } else {
        $CurrentColumn += $LargestLength + 3
        if ( $CurrentColumn + $LargestLength + 3 -ge $BufferWidth ) {
          write-host ""
          $CurrentColumn = 0
        } else {
          write-host -nonewline (" " * ($LargestLength - $Name.length))
        }
      }
    }
    if ($CurrentColumn -ne 0) {
      write-host "" # add newline at bottom
    }
  }
}
