#!/bin/bash
# 
# system management

#######################################
# creates user
# Arguments:
#   None
#######################################
system_create_user() {
  print_banner
  printf "${WHITE} 💻 Agora, vamos criar o usuário para a instancia...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  su - root <<EOF
  useradd -m -p $(openssl passwd -6 ${mysql_root_password}) -s /bin/bash -G sudo deploy
  usermod -aG sudo deploy
EOF

  sleep 2
}

#######################################
# clones repostories using git
# Arguments:
#   None
#######################################
system_git_clone() {
  print_banner
  printf "${WHITE} 💻 Fazendo download do código...${GRAY_LIGHT}"
  printf "\n\n"


  sleep 2

  su - deploy <<EOF
  git clone ${link_git} /home/deploy/${instancia_add}/
EOF

  sleep 2
}

#######################################
# updates system
# Arguments:
#   None
#######################################
system_update() {
  print_banner
  printf "${WHITE} 💻 Vamos atualizar o sistema...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  su - root <<EOF
  apt -y update
  sudo apt-get install -y libxshmfence-dev libgbm-dev wget unzip fontconfig locales gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils
EOF

  sleep 2
}



#######################################
# delete system
# Arguments:
#   None
#######################################
deletar_tudo() {
  print_banner
  printf "${WHITE} 💻 Vamos deletar o sistema selecionado...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  su - root <<EOF
  docker container rm redis-${empresa_delete} --force
  cd && rm -rf /etc/nginx/sites-enabled/${empresa_delete}-frontend
  cd && rm -rf /etc/nginx/sites-enabled/${empresa_delete}-backend  
  cd && rm -rf /etc/nginx/sites-available/${empresa_delete}-frontend
  cd && rm -rf /etc/nginx/sites-available/${empresa_delete}-backend
  
  sleep 2

  su - postgres
  dropuser ${empresa_delete}
  dropdb ${empresa_delete}
  exit
EOF

sleep 2

 su - deploy <<EOF
 rm -rf /home/deploy/${empresa_delete}
 pm2 delete ${empresa_delete}-frontend ${empresa_delete}-backend
 pm2 save
EOF

  sleep 2

  print_banner
  printf "${WHITE} 💻 Remoção da Instancia/Empresa ${empresa_delete} realizado com sucesso ...${GRAY_LIGHT}"
  printf "\n\n"


  sleep 2

}

#######################################
# bloquear system
# Arguments:
#   None
#######################################
configurar_bloqueio() {
  print_banner
  printf "${WHITE} 💻 Vamos bloquear o sistema selecionado...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

 su - deploy <<EOF
 pm2 stop ${empresa_bloquear}-backend
 pm2 save
EOF

  sleep 2

  print_banner
  printf "${WHITE} 💻 Bloqueio da Instancia/Empresa ${empresa_bloquear} realizado com sucesso ...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
}


#######################################
# desbloquear system
# Arguments:
#   None
#######################################
configurar_desbloqueio() {
  print_banner
  printf "${WHITE} 💻 Vamos desbloquear o sistema...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

 su - deploy <<EOF
 pm2 start ${empresa_bloquear}-backend
 pm2 save
EOF

  sleep 2

  print_banner
  printf "${WHITE} 💻 Desbloqueio da Instancia/Empresa ${empresa_desbloquear} realizado com sucesso ...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
}

#######################################
# alter dominio system
# Arguments:
#   None
#######################################
configurar_dominio() {
  print_banner
  printf "${WHITE} 💻 Vamos alterar os dominios...${GRAY_LIGHT}"
  printf "\n\n"

sleep 2

  su - root <<EOF
  cd && rm -rf /etc/nginx/sites-enabled/${empresa_dominio}-frontend
  cd && rm -rf /etc/nginx/sites-enabled/${empresa_dominio}-backend  
  cd && rm -rf /etc/nginx/sites-available/${empresa_dominio}-frontend
  cd && rm -rf /etc/nginx/sites-available/${empresa_dominio}-backend
EOF

sleep 2

  su - deploy <<EOF
  cd && cd /home/deploy/${empresa_dominio}/frontend
  sed -i "1c\REACT_APP_BACKEND_URL=https://${alter_backend_url}" .env
  cd && cd /home/deploy/${empresa_dominio}/backend
  sed -i "2c\BACKEND_URL=https://${alter_backend_url}" .env
  sed -i "3c\FRONTEND_URL=https://${alter_frontend_url}" .env 
EOF

sleep 2
   
   backend_hostname=$(echo "${alter_backend_url/https:\/\/}")

 su - root <<EOF
  cat > /etc/nginx/sites-available/${empresa_dominio}-backend << 'END'
server {
  server_name $backend_hostname;
  location / {
    proxy_pass http://127.0.0.1:${alter_backend_port};
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_cache_bypass \$http_upgrade;
  }
}
END
ln -s /etc/nginx/sites-available/${empresa_dominio}-backend /etc/nginx/sites-enabled
EOF

sleep 2

frontend_hostname=$(echo "${alter_frontend_url/https:\/\/}")

su - root << EOF
cat > /etc/nginx/sites-available/${empresa_dominio}-frontend << 'END'
server {
  server_name $frontend_hostname;
  location / {
    proxy_pass http://127.0.0.1:${alter_frontend_port};
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_cache_bypass \$http_upgrade;
  }
}
END
ln -s /etc/nginx/sites-available/${empresa_dominio}-frontend /etc/nginx/sites-enabled
EOF

 sleep 2

 su - root <<EOF
  service nginx restart
EOF

  sleep 2

  backend_domain=$(echo "${backend_url/https:\/\/}")
  frontend_domain=$(echo "${frontend_url/https:\/\/}")

  su - root <<EOF
  certbot -m $deploy_email \
          --nginx \
          --agree-tos \
          --non-interactive \
          --domains $backend_domain,$frontend_domain
EOF

  sleep 2

  print_banner
  printf "${WHITE} 💻 Alteração de dominio da Instancia/Empresa ${empresa_dominio} realizado com sucesso ...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
}

#######################################
# installs node
# Arguments:
#   None
#######################################
system_node_install() {
  print_banner
  printf "${WHITE} 💻 Instalando nodejs...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  su - root <<EOF
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  apt-get install -y nodejs
  sleep 2
  npm install -g npm@latest
  sleep 2
  sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
  sudo apt-get update -y && sudo apt-get -y install postgresql
  sleep 2
  sudo timedatectl set-timezone America/Sao_Paulo
EOF

  sleep 2
}
#######################################
# installs fail2ban
# Arguments:
#   None
#######################################
system_fail2ban_install() {
  print_banner
  printf "${WHITE} 💻 Instalando fail2ban...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  su - root <<EOF
  sudo apt install fail2ban -y && sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
EOF

  sleep 2
}
#######################################
# configure fail2ban
# Arguments:
#   None
#######################################
system_fail2ban_conf() {
  print_banner
  printf "${WHITE} 💻 Configurando o fail2ban...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  su - root <<EOF
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
EOF

  sleep 2
}
#######################################
# configure firewall
# Arguments:
#   None
#######################################
system_firewall_conf() {
  print_banner
  printf "${WHITE} 💻 Configurando o firewall...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  su - root <<EOF
sudo ufw default allow outgoing
sudo ufw default deny incoming
sudo ufw allow ssh
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable
EOF

  sleep 2
}
#######################################
# installs docker
# Arguments:
#   None
#######################################
system_docker_install() {
  print_banner
  printf "${WHITE} 🐋 Instalando docker...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

sudo su - root <<EOF
apt install -y apt-transport-https \
               ca-certificates curl \
               software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

ARCH=$(dpkg --print-architecture)
sudo add-apt-repository "deb [arch=\$ARCH] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

apt install -y docker-ce
EOF

  sleep 2
}

#######################################
# installs pm2
# Arguments:
#   None
#######################################
system_pm2_install() {
  print_banner
  printf "${WHITE} 💻 Instalando pm2...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  su - root <<EOF
  npm install -g pm2

EOF

  sleep 2
}

#######################################
# set timezone
# Arguments:
#   None
#######################################
system_set_timezone() {
  print_banner
  printf "${WHITE} 💻 Definindo a timezone...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  su - root <<EOF
  timedatectl set-timezone America/Sao_Paulo
EOF

  sleep 2
}


#######################################
# installs snapd
# Arguments:
#   None
#######################################
system_snapd_install() {
  print_banner
  printf "${WHITE} 💻 Instalando snapd...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  su - root <<EOF
  apt install -y snapd
  snap install core
  snap refresh core
EOF

  sleep 2
}

#######################################
# installs certbot
# Arguments:
#   None
#######################################
system_certbot_install() {
  print_banner
  printf "${WHITE} 💻 Instalando certbot...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  su - root <<EOF
  apt-get remove certbot
  snap install --classic certbot
  ln -s /snap/bin/certbot /usr/bin/certbot
EOF

  sleep 2
}

#######################################
# installs nginx
# Arguments:
#   None
#######################################
system_nginx_install() {
  print_banner
  printf "${WHITE} 💻 Instalando nginx...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  su - root <<EOF
  apt install -y nginx
  rm /etc/nginx/sites-enabled/default
EOF

  sleep 2
}

#######################################
# restarts nginx
# Arguments:
#   None
#######################################
system_nginx_restart() {
  print_banner
  printf "${WHITE} 💻 reiniciando nginx...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  su - root <<EOF
  service nginx restart
EOF

  sleep 2
}

#######################################
# setup for nginx.conf
# Arguments:
#   None
#######################################
system_nginx_conf() {
  print_banner
  printf "${WHITE} 💻 configurando nginx...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  su - root << EOF

cat > /etc/nginx/conf.d/deploy.conf << 'END'
client_max_body_size 100M;
END

EOF

  sleep 2
}

#######################################
# installs nginx
# Arguments:
#   None
#######################################
system_certbot_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando certbot, já estamos perto do fim...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  backend_domain=$(echo "${backend_url/https:\/\/}")
  frontend_domain=$(echo "${frontend_url/https:\/\/}")

  su - root <<EOF
  certbot -m $deploy_email \
          --nginx \
          --agree-tos \
          --non-interactive \
          --domains $backend_domain,$frontend_domain

EOF

  sleep 2
}
