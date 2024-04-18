#!/usr/bin/env python3

import os
import argparse
import getpass
import subprocess

def checkIfSecretExists(secretName):
    command = f"docker secret exists '{secretName}'"
    result = subprocess.run(command, shell = True, executable="/bin/sh")
    return result.returncode == 0

def deleteSecret(secretName):
    command = f"docker secret rm '{secretName}'"
    result = subprocess.run(command, shell = True, executable="/bin/sh")
    return result.returncode == 0

def saveSecret(name, secret):
    with open('/tmp/pw.tmp', 'w') as f:
        f.write(secret)

    command = f"docker secret create {name} /tmp/pw.tmp"
    result = subprocess.run(command, shell = True, executable="/bin/sh")
    os.remove("/tmp/pw.tmp")
    if result.returncode != 0:
        print(f"Error creating secret {name}")
        exit(1)

def retrieveSecret(secretName, verify=True):
    secret = getpass.getpass(f"Enter secret for {secretName}: ")

    if verify:
        print(f"Entered value starting with {secret[0]} and ending with {secret[-1]}")

    return secret

def setupSecrets(secretlist):
    for secretname in secretlist:
        secret = retrieveSecret(secretname)

        if checkIfSecretExists(secretname) == False:
            saveSecret(secretname, secret)
        else:
            print(f"Secret {secretname} already exists. Skipping.")

def updateSecret(secretName):
    updatedValue = retrieveSecret(secretName)
    if checkIfSecretExists(secretName):
        if deleteSecret(secretName):
            print(f"deleted previous {secretName}")
        else:
            print(f"Error removing existing {secretName}")
            exit(1)
    saveSecret(secretName, updatedValue)

parser = argparse.ArgumentParser(description="Setup secrets")

parser.add_argument('--setup', "-s", action="store_true", help="Setup secrets initially")
parser.add_argument('--update', "-u", help="Update provided secret")

validSecrets = []
try:
    with open('secretlist') as f:
        for line in f.readlines():
            validSecrets.append(line.strip())
except FileNotFoundError as error:
    print("'secretlist' doesn't exist. Please create 'secretlist' with each secret name on a new line.")
    exit(1)

args = parser.parse_args()

if (args.setup):
    setupSecrets(validSecrets)
    exit(0)

if args.update is not None and args.update in validSecrets:
    updateSecret(args.update)
    exit(0)

print("You must either specify `-s` or `-u [secretname]`.")
exit(1)
