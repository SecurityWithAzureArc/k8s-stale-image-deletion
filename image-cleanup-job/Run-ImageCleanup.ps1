Write-Host "Start image cleanup"

# deploy the image cleanup pods
Write-Host "Helm install image-cleanup-worker -n image-cleanup -f /job/chart/image-cleanup-worker/$env:VALUES_FILE_NAME /job/chart/image-cleanup-worker"
helm install image-cleanup-worker -n "image-cleanup" -f "/job/chart/image-cleanup-worker/$env:VALUES_FILE_NAME" "/job/chart/image-cleanup-worker"

# check if deployment was successful
if (!$?)
{
    Write-Error "Encountered error while trying to run helm upgrade"
    return 1
}

# give deployment time to finish - 90 seconds
Write-Host "Start waiting for deployment completion"
Write-Host "90 seconds left"
Start-Sleep 30
Write-Host "60 seconds left"
Start-Sleep 30
Write-Host "30 seconds left"
Start-Sleep 30

# write out logs
$pods = (& kubectl get pods -n image-cleanup -l name=imagecleanup -o json | ConvertFrom-Json).items

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
Write-Host "Helm delete image-cleanup-worker -n image-cleanup"
helm delete image-cleanup-worker -n "image-cleanup"

# check if deletion was successful
if (!$?)
{
    Write-Error "Encountered error while trying to run helm delete"
    return 1
}