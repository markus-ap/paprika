# Paprika - Powershell-TGS
Dette er eit terminalgrensesnitt skrevet i Powershell.

Det er, per no, i hovudfokus sentrert rundt hjelp med git-depotar.

## Koss installere
1. Installér Powershell / Windows terminal
1. Opne Windows terminal
1. Køyr `Set-ExecutionPolicy RemoteSigned -Scope LocalMachine` 
1. Køyr `notepad.exe $PROFILE`
1. Kopiér innhaldet av `pap.ps1` inn i den opna fila
1. Lagre fila


## Koss bruke
Etter du har gjort stega over har du tilgong til `paprika` frå kor som helst i terminalvindauget ditt.

Køyr `pap -h` for å få hjelp til koss å bruke det.

### Utval av funksjonalitet
- `pap git -sett <STI>`
    - Dette bodet setter `<STI>` til å vera mappa `paprika` ser på som hovudinngongspunktet til alle dine git-depot
- `pap git` 
    - Flyttar terminalvindauget ditt til stien satt over (`E:\Git` som startverdi)
- `pap git -l`
    - Listar ut alle depotar du har i hovudinngongspunktet ditt
- `pap git -s <SØKETERM>` 
    - Søkar etter depotar som passar med søketermet ditt
- `pap git -b <SØKETERM>`
    - Litt som `pap git -s`, men denne flyttar terminalvindauget til det fyrste resultatet av søket


