#!/bin/bash
echo -e "How many MB?"
read MB
echo -e "Creating file..."
sudo dd bs=1000024 count=$MB skip=0 if=/dev/sda of=garbage-file;
