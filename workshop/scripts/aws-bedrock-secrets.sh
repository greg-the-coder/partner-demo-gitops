kubectl delete secret aws-bedrock-config -n coder
kubectl create secret generic aws-bedrock-config -n coder \  
--from-literal=region=us-east-1 \  
--from-literal=access-key=<access-key> \
--from-literal=access-key-secret=<access-key-secret>