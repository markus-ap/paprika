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
        [string]$sett
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
            }

            $startkonfigurasjon | ConvertTo-Json | Set-Content $sti
        }

        return (Get-Content $sti | ConvertFrom-Json )
    }

    function Set-Konfigurasjon {
        param(
            [string]$Git
        )
        $sti = Get-Konfigurasjonssti
        $konfig = Get-Konfigurasjon
        $konfig.git = $Git
        $konfig | ConvertTo-Json | Set-Content $sti
    }


    $gittHjelp = $false
    function Get-Hjelp{
        param(
            [string]$Hjelp
        )
        Write-Host $Hjelp
        $gittHjelp = $true
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