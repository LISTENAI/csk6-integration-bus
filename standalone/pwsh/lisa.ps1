#!/usr/bin/env pwsh
$env:npm_config_prefix=$env:LISA_PREFIX
& "$env:LISA_PREFIX\node.exe" "$env:LISA_PREFIX\node_modules\@listenai\lisa\bin\run" $args
