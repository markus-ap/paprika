import click

@clik.command()
@click.option("--namn", prompt="Namnet ditt")
def hjelp(namn: str):
    click.echo(f"Du treng hjelp, {namn}?")

@click.command()
@click.option("github")
def github():
    click.echo("Du vil til github.com")

if __name__ = "__main__":
    hjelp()