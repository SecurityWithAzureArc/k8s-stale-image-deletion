$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path

# Build worker image

Copy-Item .\version .\image-cleanup-job\version
& docker build -t image-cleanup-job -f $ScriptDir/image-cleanup-job/Dockerfile $ScriptDir/image-cleanup-job
Remove-Item .\image-cleanup-job\version

# Build job image

& docker build -t image-cleanup-worker -f $ScriptDir/image-cleanup-worker/Dockerfile $ScriptDir/image-cleanup-worker

# Push images

& docker tag image-cleanup-job disi33/image-cleanup-job:$(Get-Content $ScriptDir/version)
& docker tag image-cleanup-job disi33/image-cleanup-job:latest
& docker push disi33/image-cleanup-job:$(Get-Content $ScriptDir/version)
& docker push disi33/image-cleanup-job:latest
& docker tag image-cleanup-worker disi33/image-cleanup-worker:$(Get-Content $ScriptDir/version)
& docker push disi33/image-cleanup-worker:$(Get-Content $ScriptDir/version)