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
RUN sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-amd64.zip" -o "awscliv2.zip" \
&& sudo unzip awscliv2.zip \
&& sudo ./aws/install
