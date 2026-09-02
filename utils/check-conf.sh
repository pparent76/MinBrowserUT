#!/usr/bin/python3
import sys

fichier = sys.argv[1]
chaine = sys.argv[2]

with open(fichier, "r", encoding="utf-8") as f:
    contenu = f.read()

sys.exit(0 if chaine in contenu else 1)
