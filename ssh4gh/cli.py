import click
import os
import subprocess
import sys

@click.group()
def cli():
    """GitHub SSH Key Manager"""
    pass

def get_script_path():
    return os.path.join(os.path.dirname(__file__), 'scripts', 'ssh4gh.sh')

@cli.command()
@click.argument('token')
@click.argument('email')
@click.argument('key_name')
@click.argument('github_username', required=False)
def add(token, email, key_name, github_username):
    """Add new SSH key"""
    cmd = [get_script_path(), 'add', token, email, key_name]
    if github_username:
        cmd.append(github_username)
    subprocess.run(cmd)

@cli.command()
@click.argument('github_token', required=False)
def list(github_token):
    """List SSH keys"""
    cmd = [get_script_path(), 'list']
    if github_token:
        cmd.append(github_token)
    subprocess.run(cmd)

@cli.command()
@click.argument('key_name')
def delete(key_name):
    """Delete SSH key"""
    subprocess.run([get_script_path(), 'delete', key_name])

def main():
    cli()

if __name__ == '__main__':
    main() 