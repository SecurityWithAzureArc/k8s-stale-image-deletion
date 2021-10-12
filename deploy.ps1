$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path

& helm upgrade image-cleanup $ScriptDir\helm --install --create-namespace --values $ScriptDir\helm\values.yaml