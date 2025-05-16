# k8s-project

### Make script executable
chmod +x k8s_deploy_tool.sh

### Run the following commands:
Check connection
./k8s_deploy_tool.sh connect

Install KEDA
./k8s_deploy_tool.sh install-keda

Deploy app
./k8s_deploy_tool.sh deploy

Check deployment health
./k8s_deploy_tool.sh health myapp default
