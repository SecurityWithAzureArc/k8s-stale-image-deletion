Write-Host "Start image cleanup"

if("$Env:WORKER_NS" -eq "")
{
    $Env:WORKER_NS="image-cleanup"
}

# deploy the image cleanup pods
Write-Host "Helm install image-cleanup-worker -f /job/chart/image-cleanup-worker/values.yaml -f /job/chart/values.yaml /job/chart/image-cleanup-worker"
helm install image-cleanup-worker -f "/job/chart/image-cleanup-worker/values.yaml" -f "/job/chart/values.yaml" "/job/chart/image-cleanup-worker"

# check if deployment was successful
if (!$?)
{
    Write-Error "Encountered error while trying to run helm upgrade"
    return 1
}

# give deployment time to finish - 90 seconds
Write-Host "Start waiting for deployment completion"
Write-Host "300 seconds left"
Start-Sleep 30
Write-Host "270 seconds left"
Start-Sleep 30
Write-Host "240 seconds left"
Start-Sleep 30
Write-Host "210 seconds left"
Start-Sleep 30
Write-Host "180 seconds left"
Start-Sleep 30
Write-Host "150 seconds left"
Start-Sleep 30
Write-Host "120 seconds left"
Start-Sleep 30
Write-Host "90 seconds left"
Start-Sleep 30
Write-Host "60 seconds left"
Start-Sleep 30
Write-Host "30 seconds left"
Start-Sleep 30

# write out logs
$pods = (& kubectl get pods -n $Env:WORKER_NS -l name=imagecleanup -o json | ConvertFrom-Json).items

Write-Host "image cleanup results:"
Write-Host ""
Write-Host "============================================="
$pods | ForEach-Object {
    Write-Host ""
    $podName =  $_.metadata.name
    $podNamespace =  $_.metadata.namespace
    $nodeName = $_.spec.nodeName
    Write-Host "Pod $podNamespace/$podName on node $nodeName"
    Write-Host ""
    $describeOut = $( kubectl describe pod -n $podNamespace $podName )
    Write-Host $describeOut
    Write-Host ""
    $logsOut = $( kubectl logs -n $podNamespace $podName )
    Write-Host $logsOut
    Write-Host ""
    Write-Host "============================================="
} 

# remove image cleanup deployment
Write-Host "Helm delete image-cleanup-worker -n $Env:WORKER_NS"
helm delete image-cleanup-worker -n "$Env:WORKER_NS"

# check if deletion was successful
if (!$?)
{
    Write-Error "Encountered error while trying to run helm delete"
    return 1
}