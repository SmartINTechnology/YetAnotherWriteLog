﻿function Write-Log {
    <#
        .SYNOPSIS

        Single function to enable logging to file. Test
        .DESCRIPTION

        The Log file can be output to any directory. A single log entry looks like this:
        2018-01-30 14:40:35 INFO:    'My log text'

        Log entries can be Info, Warning, Error or Debug

        The function takes pipeline input and you can even pipe exceptions straight to the function for automatic logging.

        The $PSDefaultParameterValues built-in Variable can be used to conveniently set the path and/or JSONformat switch at the top of the script:

        $PSDefaultParameterValues = @{"Write-Log:Path" = 'C:\YourPathHere'}

        $PSDefaultParameterValues = @{"Write-Log:JSONformat" = $true}

        .PARAMETER Message

        This is the body of the log line and should contain the information you wish to log.
        .PARAMETER Level

        One of four logging levels: INFO, WARNING, ERROR or DEBUG.  This is an optional parameter and defaults to INFO
        .PARAMETER Path

        The path where you want the log file to be created.  This is an optional parameter and defaults to "$env:temp\PowershellScript.log"
        .PARAMETER StartNew

        This will blank any current log in the path, it should be used at the start of a script when you don't want to append to an existing log.
        .PARAMETER Exception

        Used to pass a powershell exception to the logging function for automatic logging
        .PARAMETER JSONFormat

        Used to change the logging format from human readable to machine readable format, this will be a single line like the example format below:
        In this format the timestamp will include a much more granular time which will also include timezone information.

        {"TimeStamp":"2018-02-01T12:01:24.8908638+00:00","Level":"Warning","Message":"My message"}

        .EXAMPLE
        Write-Log -StartNew
        Starts a new logfile in the default location

        .EXAMPLE
        Write-Log -StartNew -Path c:\logs\new.log
        Starts a new logfile in the specified location

        .EXAMPLE
        Write-Log 'This is some information'
        Appends a new information line to the log.

        .EXAMPLE
        Write-Log -level Warning 'This is a warning'
        Appends a new warning line to the log.

        .EXAMPLE
        Write-Log -level Error 'This is an Error'
        Appends a new Error line to the log.

        .EXAMPLE
        Write-Log -Exception $error[0]
        Appends a new Error line to the log with the message being the contents of the exception message.

        .EXAMPLE
        $error[0] | Write-Log
        Appends a new Error line to the log with the message being the contents of the exception message.

        .EXAMPLE
        'My log message' | Write-Log
        Appends a new Info line to the log with the message being the contents of the string.

        .EXAMPLE
        Write-Log 'My log message' -JSONFormat
        Appends a new Info line to the log with the message. The line will be in JSONFormat.
    #>

    [CmdletBinding(DefaultParametersetName = "LOG")]
    Param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'LOG',
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'LOG',
            Position = 1 )]
        [ValidateSet('Error', 'Warning', 'Info', 'Debug')]
        [string]$Level = "Info",

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 2)]
        [string]$Path = "$env:temp\PowershellScript.log",

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [switch]$JSONFormat,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'STARTNEW')]
        [switch]$StartNew,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'EXCEPTION')]
        [System.Management.Automation.ErrorRecord]$Exception
    )

    BEGIN {
        Set-StrictMode -version Latest #Enforces most strict best practice.
    }

    PROCESS {
        #Switch on parameter set
        switch ($PSCmdlet.ParameterSetName) {
            LOG {
                #Get human readable date
                $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

                switch ( $Level ) {
                    'Info' { $LevelText = "INFO:   "; break }
                    'Error' { $LevelText = "ERROR:  "; break }
                    'Warning' { $LevelText = "WARNING:"; break }
                    'Debug' { $LevelText = "DEBUG:  "; break }
                }

                #Build an object so we can later convert it

                $logObject = [PSCustomObject]@{
                    TimeStamp = Get-Date -Format o  #Get machine readable date
                    Level     = $Level
                    Message   = $Message
                }

                if ($JSONFormat) {
                    #Convert to a single line of JSON and add it to the file
                    $logmessage = $logObject | ConvertTo-Json -Compress
                    $logmessage | Add-Content -Path $Path
                }
                else {
                    $logmessage = "$FormattedDate`t$LevelText`t$Message" #Build human readable line
                    $logObject | Export-Csv -Path $Path -Delimiter "`t" -NoTypeInformation -Append
                }

                Write-Verbose $logmessage #Only verbose line in the function

            } #LOG

            EXCEPTION {
                #Splat parameters
                $WriteLogParams = @{
                    Level      = 'Error'
                    Message    = $Exception.Exception.Message
                    Path       = $Path
                    JSONFormat = $JSONFormat
                }
                Write-Log @WriteLogParams #Call itself to keep code clean
                break

            } #EXCEPTION

            STARTNEW {
                if (Test-Path $Path) {
                    Remove-Item $Path -Force
                }
                #Splat parameters
                $WriteLogParams = @{
                    Level      = 'Info'
                    Message    = 'Starting Logfile'
                    Path       = $Path
                    JSONFormat = $JSONFormat
                }
                Write-Log @WriteLogParams
                break

            } #STARTNEW

        } #switch Parameter Set
    }

    END {
    }
} #function
