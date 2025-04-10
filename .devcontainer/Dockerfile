FROM codercom/enterprise-base:ubuntu

#Add on Coder Admin utilities
# Packages to download and unzip Terraform
RUN apt-get update && apt-get install -y \
    wget \
    unzip 

# Download and install Terraform
RUN wget --quiet https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip \
    && unzip terraform_1.6.6_linux_amd64.zip \
    && mv terraform /usr/bin \
    && rm terraform_1.6.6_linux_amd64.zip

# Verify installation
RUN terraform --version
