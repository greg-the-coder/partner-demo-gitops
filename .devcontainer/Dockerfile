FROM codercom/enterprise-base:ubuntu
#Add on Coder Admin utilities
# Packages to download and unzip Terraform
RUN sudo apt-get update && sudo apt-get install -y \
    wget \
    unzip \
    && sudo rm -rf /var/lib/apt/lists/*

# Download and install Terraform
RUN wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list \
&& sudo apt update && sudo apt install terraform

# Verify installation
RUN terraform --version