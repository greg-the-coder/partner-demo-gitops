data "coder_workspace_preset" "pacman" {
  name        = "PAC-MAN"
  description = "Play PAC-MAN on any development environment!"
  icon        = "https://assets.stickpng.com/images/5a18871c8d421802430d2d05.png"
  parameters = {
    (data.coder_parameter.cpu.name)            = 4
    (data.coder_parameter.memory.name)         = 8
    (data.coder_parameter.disk_size.name)      = 25
    (data.coder_parameter.image.name)          = "codercom/enterprise-node:latest"
    (data.coder_parameter.repo.name)           = "https://github.com/coder-contrib/pacman-nodejs"
    (data.coder_parameter.startup-script.name) = <<-EOF
      curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
        sudo gpg --batch --yes -o /usr/share/keyrings/mongodb-server-8.0.gpg \
        --dearmor || true

      echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu $DISTRIB_CODENAME/mongodb-org/8.2 multiverse" | \
        sudo tee /etc/apt/sources.list.d/mongodb-org-8.2.list

      DEBIAN_FRONTEND="noninteractive" \
        sudo apt-get update -y && \
        sudo apt-get install -y mongodb-org || true
      echo "Package Installation complete!"

      echo "Setting NPM installation prefix..."
      npm config set prefix ~/.local

      echo "Starting MongoDB in the background..."
      nohup sudo -u mongodb mongod --config /etc/mongod.conf > /tmp/mongodb.out 2> /tmp/mongodb.err &
      echo $! > /tmp/mongodb.pid

      cd ${local.home_dir}/pacman-nodejs
      yarn install
      nohup npm start > /tmp/pacman.out 2> /tmp/pacman.err &
      echo $! > /tmp/pacman.pid
    EOF
  }
}