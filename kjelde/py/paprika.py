import click, os, subprocess, requests
from azure.identity import DefaultAzureCredential


@click.group()
def tgs():
    pass

@tgs.command()
def opp():
    """Går opp ei mappe i hierarkiet"""
    reesultat = subprocess.run("py print('Hei, der!')", shell=True)
    click.secho(f"Går opp...", fg="red")
    click.echo(reesultat)


@tgs.command()
def login():
    """Loggar inn i Azure   """
    try:
        subprocess.run("az login", shell=True   );
        credential = DefaultAzureCredential()
        token = credential.get_token("https://management.azure.com//.default")
        click.echo(f"Authenticated successfully. Access token: {token.token}")
    except Exception as e:
        click.echo(f"Error authenticating: {e}")

@tgs.command()
@click.option("-m", help="Melding til discord.")
def discord(m):
    """Send melding til Discord"""
    url = ""
    
    kropp = {
        "content": f"prompt:{m}"
    }
    svar = requests.post(url, json=kropp)
    click.echo(svar)