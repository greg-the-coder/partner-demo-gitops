FROM codercom/enterprise-base:ubuntu
#Add on Coder Admin utilities
# Packages to download and unzip Terraform
RUN sudo apt-get update && sudo apt-get install -y \
    wget \
    unzip \
    curl \
    && sudo rm -rf /var/lib/apt/lists/*

# Install Terraform
RUN wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list \
&& sudo apt update && sudo apt install terraform

# Install AWS CLI
RUN sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
&& sudo unzip awscliv2.zip \
&& sudo ./aws/install && sudo rm awscliv2.zip

#Install Helm
RUN sudo curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
&& sudo chmod 700 get_helm.sh \
&& sudo ./get_helm.sh

#Install Kubectl
RUN sudo curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
RUN sudo echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install kubectl
RUN sudo curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl" \
&& sudo chmod +x kubectl \
&& sudo mv kubectl /usr/local/bin/

