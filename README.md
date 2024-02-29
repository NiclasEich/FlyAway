# FlyAway
Neovim Plugin for syncing files to a remote host

## Commands

### FlyAwaySync 

This command is used for syncing directories with a remote machine. It takes one argument, which can be 'push' or 'pull'.

Example usage: `:FlyAwaySync push`

### FlyAwaySyncFast 

This command repeats the last sync operation, either push or pull. It takes one argument, which can be 'push' or 'pull'.

Example usage: `:SyncFast pull`

### FlyAwayLogs 

This command shows the logs of the last sync operation.

Example usage: `:SyncOutput`


## Installation with Packer
If you are using Packer as your NeoVim plugin manager, you can add the following line to your Packer configuration:

```
use 'NiclasEich/FlyAway'
```
