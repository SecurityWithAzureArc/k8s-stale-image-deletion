# k8s-stale-image-deletion
A solution for deleting stale images from k8s clusters.


- create a shell inside a container: `kubectl exec -it -n <namespace>   <pod> -- /bin/bash`
- create a job from cronjob definition: `kubectl create job --from=cronjob/image-cleanup-cronjob -n test <jobname>`


Install nginx helm deployment for testing:
`helm repo add nginx-stable https://helm.nginx.com/stable`
`helm repo update`
`helm install nginx nginx-stable/nginx-ingress`

Build docker images and push to dockerhub:
`./build.ps1`

Deploy helm chart to cluster (current context needs to be set correctly for kubectl):
`./deploy.ps1`