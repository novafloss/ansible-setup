FROM debian:wheezy
RUN apt-get update -y
RUN apt-get install -y python-virtualenv python-dev libffi-dev libssl-dev
RUN apt-get install -y git && git clone --depth=1 --recursive https://github.com/ansible/ansible.git /opt/ansible && apt-get autoremove -y git
RUN virtualenv /opt/ansible_env
RUN /opt/ansible_env/bin/pip install -e /opt/ansible
RUN ln -sfn /opt/ansible_env/bin/ansible* /usr/bin
COPY ansible.cfg /root/.ansible.cfg
RUN mkdir -p /root/.ansible_setup/plugins/callback
COPY plugins/callback/default.py /root/.ansible_setup/plugins/callback
