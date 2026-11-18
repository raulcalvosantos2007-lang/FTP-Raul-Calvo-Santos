# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Imagen base común para las dos máquinas.
  config.vm.box = "debian/bookworm64"

  # Se mantiene la clave SSH insegura de la imagen base para simplificar
  # las conexiones de Ansible durante la práctica.
  config.ssh.insert_key = false

  # Servidor DNS: dns.raul.test (192.168.57.5)
  config.vm.define "dns" do |dns|
    dns.vm.hostname = "dns.raul.test"
    dns.vm.network "private_network", ip: "192.168.57.5"
  end

  # Servidor web y FTP seguro: negocio.raul.test (192.168.57.7)
  config.vm.define "negocio" do |negocio|
    negocio.vm.hostname = "negocio.raul.test"
    negocio.vm.network "private_network", ip: "192.168.57.7"
  end
end
