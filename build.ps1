$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path

# Build worker image

& docker build -t image-cleanup-job -f $ScriptDir/image-cleanup-job/Dockerfile $ScriptDir/image-cleanup-job

# Build job image

& docker build -t image-cleanup-worker -f $ScriptDir/image-cleanup-worker/Dockerfile $ScriptDir/image-cleanup-worker

# Push images

& docker tag image-cleanup-job disi33/image-cleanup-job
& docker push disi33/image-cleanup-job
& docker tag image-cleanup-worker disi33/image-cleanup-worker
& docker push disi33/image-cleanup-worker