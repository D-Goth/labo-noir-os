#!/bin/bash
TARGET=$(yad --entry --title="Nmap" --text="Cible :")
OPTIONS=$(yad --list --checklist --title="Options" \
  --column="Sélection" --column="Option" \
  FALSE "-sV" FALSE "-O" FALSE "-p-")
x-terminal-emulator -e nmap $OPTIONS $TARGET
