$path = Split-Path -Parent -Path (Split-Path -Parent -Path $MyInvocation.MyCommand.Path)
Import-Module "$($path)/src/Pode.psm1" -Force -ErrorAction Stop

# or just:
# Import-Module Pode

$LOGGING_TYPE = 'Terminal' # Terminal, Fiie, Custom

# create a server, and start listening on port 8085
Start-PodeServer {

    Add-PodeEndpoint -Address *:8085 -Protocol Http
    Set-PodeViewEngine -Type Pode

    switch ($LOGGING_TYPE.ToLowerInvariant()) {
        'terminal' {
            New-PodeLoggingType -Terminal | Enable-PodeRequestLogging
        }

        'file' {
            New-PodeLoggingType -File -Name 'requests' -MaxDays 4 | Enable-PodeRequestLogging
        }

        'custom' {
            $type = New-PodeLoggingType -Custom -ScriptBlock {
                param($item)
                # send request row to S3
            }

            $type | Enable-PodeRequestLogging
        }
    }

    # GET request for web page on "localhost:8085/"
    Add-PodeRoute -Method Get -Path '/' -ScriptBlock {
        Write-PodeViewResponse -Path 'simple' -Data @{ 'numbers' = @(1, 2, 3); }
    }

    # GET request throws fake "500" server error status code
    Add-PodeRoute -Method Get -Path '/error' -ScriptBlock {
        Set-PodeResponseStatus -Code 500
    }

    # GET request to download a file
    Add-PodeRoute -Method Get -Path '/download' -ScriptBlock {
        Set-PodeResponseAttachment -Path 'Anger.jpg'
    }

}
