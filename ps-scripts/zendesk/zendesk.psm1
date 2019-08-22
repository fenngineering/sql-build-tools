function Get-ZenDeskUser(){
    
    [CmdletBinding(DefaultParameterSetName="Filter")]
    Param(

        [Parameter(
            Position=0,
            ValueFromPipeline=$true,
            Mandatory=$true
        )]
        [ValidateScript({
            if ((Verify-ZenDeskObject $_) -eq $false) { Write-Host "ZenDeskObject failed validation. Use Initalize-ZenDeskObject to create the Object." -ForegroundColor Yellow; return $false}
            if ($_.Authenticated -eq $false) {Write-Host "Not Authenticated. Use Connect-ZenDeskOlService to Authenticate." -ForegroundColor Yellow; return $false}
            return $true
        })] 
        $ZenDeskObj,
        
        [Parameter(
            ParameterSetName='Identity',
            Mandatory=$true,
            Position=1
            )]
        [String[]]
        $Identity,

        [Parameter(
            ParameterSetName='Filter',
            Mandatory=$true,
            Position=1
            )]          
        [ScriptBlock]
        $Filter,

        [Parameter(
            ParameterSetName='AllUsers',
            Mandatory=$true,
            Position=1
            )]          
        [Switch]
        $AllUsers,

        [Parameter(
            Position=3,
            Mandatory=$false
        )]
        [Int]
        $ResultSize,



        [Parameter(
            Position=4,
            Mandatory=$false
        )]
        [String[]]
        $Properties,

        [Parameter(
            Position=5,
            Mandatory=$false
        )]
        $ZenDeskUserCollection        
    )



    begin {
            



            $webregparam = @{



                Uri = $ZenDeskObj.URI+'/api/v2/users.json'
                Headers = @{Authorization=("Basic {0}" -f $ZenDeskObj.base64AuthAPIToken)};
                Method = 'Get';
                



            }  



            # If Identity was used, try parse identity as an integer. If sucessfull, change $webregparam.uri to 
            if ($identity) {



                
                try { 
                    
                    # try parse
                    [int64]$userid = [convert]::ToInt64($identity, 10)
                    # Then Update URI
                    $webregparam.Uri = $ZenDeskObj.URI+'/api/v2/users/'+$userid+'.json' 



                }
                catch {}
            
            }
          
    }



    process {
        
        $objparam = @{}
        $errorFunctionName = "Get-ZenDeskUser"



        # If the ZenDeskUserCollection was passed into the cmdlet then it will process from that rather then doing a REST Call. This saves having to perform multiple calls.
        if ($ZenDeskUserCollection) {



            $usersCollection = $ZenDeskUserCollection



            # If the count exceeds the result size. Get the results size and stop 
            if (($usersCollection.Count -ge $ResultSize) -and $ResultSize) {



                $usersCollection = $usersCollection | Select -first $ResultSize



            }



        } else {
            
            # Else. Perform a REST call to ZenDesk



            try {
        
                # Build List
                Do {



                    # Invoke REST Method
                    $invokemethod = Invoke-RestMethod @webregparam -ErrorAction SilentlyContinue -ErrorVariable errorInvokeRestMethod
                    
                    # If the User property exists from calling a single user rather then a collection. Update the collection and then break the loop.
                    if ($invokemethod.User) {



                        $usersCollection = $invokemethod.User
                        break



                    }
                    # Update userCollection
                    $usersCollection += $invokemethod.Users



                    # If the count exceeds the result size. Get the results size and stop
                    if ($ResultSize) {
                        if ($usersCollection.Count -ge $ResultSize) {



                            $usersCollection = $usersCollection | Select -first $ResultSize
                            break



                        }
                    }



                    # Update Uri
                    $webregparam.Uri = $invokemethod.next_page



                }
                Until (!($invokemethod.next_page) -or ($invokemethod.next_page -eq $null))
            
            }
            catch {



                $objparam.Error = $true
                $objparam.errorMessage = $errorInvokeRestMethod.Message
                $objparam.errorFunctionName = $errorFunctionName



            }



        }



    }



    end {



        # Does the Collection Exist?



        if ($usersCollection) {
        
            # Was the Filter Parameter Specified?
            if ($filter) {



                # If the $Properties switch was specified, then select those properties.
                if ($Properties) {
                           
                    return ($usersCollection | Where-Object -FilterScript $Filter | Select $Properties)



                } else {



                    return ($usersCollection | Where-Object -FilterScript $Filter | Select id,url,name,email,time_zone,phone)



                }



            }



            # Was the Filter Parameter Specified?
            if ($Identity) {



                # If the $Properties switch was specified, then select those properties.
                if ($Properties) {
                    
                    # Does $userid exist? If it does then a single user was obtained. Return the single object rather then performing a where-object.
                    if ($userid) {
                        
                        return ($usersCollection | Select $Properties)



                    } else {



                        return ($usersCollection | Where-Object {(($_.Name -eq $Identity) -or ($_.Email -eq $Identity))} | Select $Properties)



                    }



                } else {



                    # Does $userid exist? If it does then a single user was obtained. Return the single object rather then performing a where-object.
                    if ($userid) {
                        
                        return ($usersCollection | Select id,url,name,email,time_zone,phone)



                    } else {



                        return ($usersCollection | Where-Object {(($_.Name -eq $Identity) -or ($_.Email -eq $Identity))} | Select id,url,name,email,time_zone,phone)



                    }



                }
                
            }



            # Was the All Users switch specified?
            if ($AllUsers) {



                # If the $Properties switch was specified, then select those properties.
                if ($Properties) {
                           
                    return ($usersCollection | Select $Properties)



                } else {



                    return ($usersCollection | Select id,url,name,email,time_zone,phone)



                }



            }



        }
        elseif ($objparam) {
            
            return ($objparam)
        
        } 
        else {
        
            throw 'No object return for $invokemethod. Function: Get-ZenDeskUser'



        }
            
    }