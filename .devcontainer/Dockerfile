FROM codercom/enterprise-base:ubuntu
#Add on Coder Admin utilities
# Packages to download and unzip Terraform
RUN sudo apt-get update && sudo apt-get install -y \
    wget \
    unzip \
    && sudo rm -rf /var/lib/apt/lists/*

# Download and install Terraform
RUN wget --quiet https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip \
    && unzip terraform_1.6.6_linux_amd64.zip \
    && sudo mv terraform /usr/bin \
    && sudo rm terraform_1.6.6_linux_amd64.zip

# Verify installation
RUN terraform --version
