function pap{
    param(
        [string]$bod,
        [switch]$h,
        [string]$m, # Melding for diverse bod

        # Github
        [switch]$k,
        [switch]$g,
        [switch]$mf,
        [switch]$dult,

        # Git
        [switch]$l,
        [string]$s,
        [string]$b,
        [string]$i,
        [string]$sett,

        # GPT
        [switch]$t
    )

    function Get-Konfigurasjonssti{
        $konfigMappe = Join-Path -Path $env:APPDATA -ChildPath "paprika"
        $sti = Join-Path -Path $konfigMappe -ChildPath "konfigurasjon.json"
        
        if (-not (Test-Path $konfigMappe)) {
            New-Item -Path $konfigMappe -ItemType Directory
        }
        return $sti
    }

    function Get-Konfigurasjon{
        $sti = Get-Konfigurasjonssti
        if( -not (Test-Path $sti) ){
            $startkonfigurasjon = @{
                git = "E:\Git"
                gpt = @{
                    "openai_api_key" = ""
                    "gen_images" = @()
                    "messages" = @(
                        @{
                             "role" =  "system"
                              "content" = "You are a quirky, but helpful, assistant called Paprika." 
                        }
                    )
                }
            }

            $startkonfigurasjon | ConvertTo-Json -Depth 5 | Set-Content $sti
        }

        return (Get-Content $sti | ConvertFrom-Json )
    }

    function Set-Konfigurasjon {
        param(
            [string]$Git,
            [object]$Gpt
        )
        $sti = Get-Konfigurasjonssti
        $konfig = Get-Konfigurasjon

        if($Git){
            $konfig.git = $Git
        }
        if( $Gpt ){
            $konfig.gpt = $Gpt
        }
        $konfig | ConvertTo-Json -Depth 5 | Set-Content $sti
    }


    $gittHjelp = $false
    function Get-Hjelp{
        param(
            [string]$Hjelp
        )
        Write-Host $Hjelp
        $gittHjelp = $true
    }

    function Get-GptBilete{
        param(
            [string]$Skildring
        )
        $gptKon = (Get-Konfigurasjon).gpt

        $kropp = @{
            "prompt" = $Skildring
            "n" = 2
            "size" = "1024x1024"
        } | ConvertTo-Json -Depth 5

        $nokkel = $gptKon.openai_api_key

        $overskriftar = @{
            "Authorization" = "Bearer $($nokkel)"
            "Content-Type" = "application/json"
        }

        $svar = (Invoke-WebRequest -Method POST -Uri "https://api.openai.com/v1/images/generations" -Body $kropp -Headers $overskriftar)

        $svarMelding = ($svar.Content | ConvertFrom-Json).data

        $returSvar = ($svarMelding | ForEach-Object { $_.url } )

        $bileteObjekt = $svarMelding | ForEach-Object {
            @{
                "url" = $_.url
                "prompt" = $Skildring
            }
        }
        
        $gptKon.gen_images += $bileteObjekt
        Set-Konfigurasjon -Gpt $gptKon

        return $returSvar

    }

    function Get-GptSvar{
        param(
            [string]$Melding
        )

        $gptKon = (Get-Konfigurasjon).gpt

        $meldingObjekt = @{
            "role" = "user"
            "content"= "$Melding"
        }

        $meldingar = $gptKon.messages

        $meldingar += $meldingObjekt

        $kropp = @{
            "model" = "gpt-3.5-turbo"
            "messages" = $meldingar
            "temperature" = 0.7
        } | ConvertTo-Json -Depth 5

        $nokkel = $gptKon.openai_api_key

        $overskriftar = @{
            "Authorization" = "Bearer $($nokkel)"
            "Content-Type" = "application/json"
        }

        $svar = (Invoke-WebRequest -Method POST -Uri "https://api.openai.com/v1/chat/completions" -Body $kropp -Headers $overskriftar)

        $svarMelding = ($svar.Content | ConvertFrom-Json).choices[0].message

        $meldingar += $svarMelding

        $gptKon.messages = $meldingar

        Set-Konfigurasjon -Gpt $gptKon

        return $svarMelding.content
    }

    function Get-GitHovudmappe{
        return (Get-Konfigurasjon).git
    }

    function Get-Grein{
        return (git symbolic-ref --short HEAD)
    }

    function Get-DepotUrl{
        $grein = (Get-Grein)
        $fjern = (git config --get "branch.$grein.remote")
        return (git config --get "remote.$fjern.url") -replace "\.git$", ""
    }

    function Get-GreinUrl{
        $url = (Get-DepotUrl)
        $grein = (Get-Grein)
        return "$url\tree\$grein"
    }

    function Get-GitMappar{
        return Get-ChildItem -Path (Get-GitHovudmappe) -Filter ".git" -Recurse -ErrorAction SilentlyContinue -Force -Directory | ForEach-Object { $_.Parent }
    }

    function Get-GitMapparMedInnhald{
        param(
            [string]$Sok
        )
        $gitMappar = (Get-GitMappeStiar)

        foreach ($depot in $gitMappar) {
            $filar = Get-ChildItem -Path $depot -Filter $Sok -Recurse -ErrorAction SilentlyContinue -Force -File
            if ($filar) {
                Write-Output (Split-Path $depot -Leaf)
            }
        }
    }

    function Find-GitMappe{
        param(
            [string]$Sok
        )

        return (Get-GitMappar) | Where-Object { $_.Name -Match $Sok } 
    }

    function Get-GitMappeStiar{
        return (Get-GitMappar) | ForEach-Object { $_.FullName }
    }

    function Get-GitMappenamn{
        return (Get-GitMappar) | ForEach-Object { $_.Name }
    }

    $gitHovudmappe = (Get-GitHovudmappe)

    $hjelpKonfig = @"
--- Konfigurasjon ---
Bruk pap kon for å sjå Paprikas konfigurasjon.

pap kon
"@

    $hjelpTay = @"
--- Taylor Swift ---
Bruk pap tay for hjelp med Taylor Swift.

pap tay -s <SØKETERM> (Opnar vevside med søk etter <SØKETERM> i Taylor Swifts låttekstar)
"@

    $hjelpPy = @"
--- Python ---
Bruk pap py for hjelp med python.

pap py -k (Lagar krav.txt i depotet du står i)
"@

    $hjelpGit = @"
--- Git ---
Bruk pap git for å ta deg til mappa med alle git-depota.

pap git -sett <MAPPE> (Sett rotmappe for dine gitprosjekt)

pap git (endre lokasjon i terminal til $gitHovudmappe)
pap git dult -m "<MELDING>" (Køyrar git add ., git commit -m "<MELDING>", git push)

pap git -l (Listar alle git-mappar i hovudgitmappa di)
pap git -s <SØKETERM> (Søkar etter gitmappar i hovudgitmappa di)

pap git -b <SØKETERM> (Flyttar terminalen din til fyrste resultat av søk etter gitmappe)

pap git -i <SØKETERM> (Visar gitmappar med innhald som passar til søketermet ditt.)
"@

    $hjelpGithub = @"
--- Github ---
Bruk pap github for å hjelpe deg med å opne diverse github-lenkjar.

pap github (Opnar github.com til depotet du står i)
pap github -k (Opnar samlekøa i github.com til depotet du står i)
pap github -g (Opnar greina du står i på github.com)
pap github -g -mf (Opnar meldingsførespunad av greina du står i på github.com)
"@

    $hjelpGpt = @"
--- GPT ---
Bruk pap gpt for å prate med paprika.

pap gpt -sett "<OPENAI_API-NØKKEL>" (Sett API-nøkkelen din for Open AI for å bruke GPT)

pap gpt -m "<MELDING>" (Send melding til paprika)
pap gpt -b "<BILETE_SKILDRING"> (be paprika lage bilete til deg)

pap gpt -t (Tømmar meldingshistorikken din med paprika, nyttig dersom historikken blir full)

For å lese meldingshistorikken bruk pap kon. Historikken ligger i konfigurasjonsfila til paprika.
"@

    $hjelp = @"
--- Paprika hjelp ---

$hjelpKonfig

$hjelpGit

$hjelpGithub
"@
    if (-not [string]::IsNullOrEmpty($bod)) {
        $bod = $bod.ToLower()
    } elseif ( $h ){
        Get-Hjelp -Hjelp $hjelp
        break
    }
    switch ($bod){
        "hjelp"{
            Get-Hjelp -Hjelp $hjelp
            break
        }
        "gpt"{            
            if( $h ){
                Get-Hjelp -Hjelp $hjelpGpt
                break
            }

            if( $m ){
                $svar = (Get-GptSvar -Melding $m)
                $linjar = $svar -split "`n"
                $skriveLinjar = ($linjar | ForEach-Object {"`t" + $_} ) -join "`n"
                Write-Host "Paprika:" 
                Write-Host $skriveLinjar
            }

            if( $b ){
                $svar = (Get-GptBilete -Skildring $b)
                Write-Host $svar
                $svar | ForEach-Object { Start-Process $_ }
                break
            }

            if( $t ){
                $gptKonfig = (Get-Konfigurasjon).gpt
                $gptKonfig.messages = @(
                    @{
                        "role" =  "system"
                        "content" =  "You are a quirky, but helpful, assistant called Paprika."  
                    }
                )

                Set-Konfigurasjon -Gpt $gptKonfig

                Write-Host "Tømte meldingshistorikk."
                break
            }           

            if( $sett ){
                $kon = Get-Konfigurasjon
                $kon.gpt.openai_api_key = $sett 

                Set-Konfigurasjon -Gpt $kon.gpt
            }
        }
        "git"{
            if( $h ){
                Get-Hjelp -Hjelp $hjelpGit
                break
            }
            if( $l ){
                (Get-GitMappar) | ForEach-Object { Write-Host "- $_" }
                break
            }
            if( $s ){
                (Find-GitMappe -Sok $s) | ForEach-Object { Write-Host "- $_" }
                break
            }
            if( $i ){
                Get-GitMapparMedInnhald -Sok $i | ForEach-Object { Write-Host "- $_" }
                break
            }
            if( $b ){
                $mappe = (Find-GitMappe -Sok $b) | Select-Object -first 1
                Set-Location $mappe.FullName
                break
            }
            if( $sett ){
                Set-Konfigurasjon -Git $sett
                break
            }
            if( $dult ){
                if( -not $m ){
                    Write-Host "Du manglar -m '<MELDING>'. Sjå pap git -h"
                    break
                }
                git add .
                git commit -m $m 
                git push 
            }
            Set-Location (Get-GitHovudmappe)
            break
        }
        "py"{            
            if( $h ){
                Get-Hjelp -Hjelp $hjelpPy
                break
            }
            if( $k ){
                pipreqs --savepath krav.txt --encoding utf8
                break
            }
        }
        "github"{
            if( $h ){
                Get-Hjelp -Hjelp $hjelpGithub
                break
            }
            $url = (Get-DepotUrl)
            if( $g ){
                $url = (Get-GreinUrl)
                if( $mf ){
                    $grein = (Get-Grein)
                    $depotUrl = (Get-DepotUrl)
                    $url = "$depotUrl\compare\$grein\?compare"
                }
            } elseif( $k ){
                $depotUrl = (Get-DepotUrl)
                $url = "$depotUrl\queue"
            }

            Start-Process $url 
            break
        }
        "tay"{
            if( $h ){
                Get-Hjelp -Hjelp $hjelpTay
                break
            }
            if( $s ){
                $url = "https://shaynak.github.io/taylor-swift?query=$s&album=Taylor%20Swift&album=Fearless&album=Speak%20Now&album=Red&album=1989&album=Midnights&album=evermore&album=folklore&album=Lover&album=reputation"
                Start-Process $url 
                break
            }
        }
        "red"{
            code $PROFILE
            break
        }
        "kon"{
            if( $h ){
                Get-Hjelp -Hjelp $hjelpKonfig
                break
            }
            $sti = Get-Konfigurasjonssti
            code $sti
            return $sti
        }
        default{
            Write-Host "Ukjent bod. Prøv pap -h for hjelp."
            break
        }
    }
}