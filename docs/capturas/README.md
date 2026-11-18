# Capturas de la práctica

El enunciado del PDF no exige capturas, pero esta carpeta recoge **exactamente**
qué imágenes hay que tomar para documentar que la práctica se ha ejecutado.

> No se han generado capturas falsas. Cada una debe obtenerse ejecutando el
> comando indicado en el entorno real (WSL/Ubuntu como nodo de control) y
> guardando la imagen en esta carpeta con el nombre propuesto.

Antes de empezar, configura el DNS del anfitrión con `192.168.57.5` o usa las
opciones `--resolve` / `@IP` que se indican en los comandos.

---

## 01. Estado de las máquinas

```bash
vagrant status
```

Guardar como `01-vagrant-status.png`.  
Debe verse `dns` y `negocio` con estado `running`.

## 02. Configuración SSH de Vagrant

```bash
vagrant ssh-config
```

Guardar como `02-vagrant-ssh-config.png`.  
Debe aparecer `User vagrant` y la ruta de `IdentityFile` usada en
`ansible.cfg`.

## 03. Inventario de Ansible

```bash
ansible-inventory --graph
```

Guardar como `03-inventario.png`.  
Deben aparecer los alias `dns` y `negocio` con sus IPs.

## 04. Conectividad Ansible

```bash
ansible all -m ping
```

Guardar como `04-ansible-ping.png`.  
Respuesta `pong` para `dns` y `negocio`.

## 05. Resolución DNS

```bash
./dns/test-dns.sh
```

Guardar como `05-pruebas-dns.png`.  
Todas las líneas deben empezar por `OK` y terminar con
`Todas las comprobaciones DNS han pasado.`

## 06. Servidor web

```bash
./web/test-web.sh
```

Guardar como `06-prueba-web.png`.  
Debe mostrar `OK: http://www.raul.test/ responde y contiene Servidor web de raul.test`.

También se puede capturar el navegador en `http://www.raul.test` como
`06b-navegador-web.png`.

## 07. Ejecución del playbook FTP

```bash
ansible-playbook ftp/ftp.yml --ask-vault-pass
```

Guardar como `07-playbook-ftp.png`.  
Deben aparecer todas las tareas como `ok` o `changed`, sin errores.

## 08. Certificado TLS

```bash
openssl s_client -connect ftp.raul.test:21 -starttls ftp -showcerts </dev/null
```

Guardar como `08-certificado-tls.png`.  
Debe verse `subject=CN = ftp.raul.test` y el SAN `DNS:ftp.raul.test`.

## 09. Cliente FTP con `ana`

En FileZilla:

- Servidor: `ftp.raul.test`, puerto `21`.
- Cifrado: **FTP explícito sobre TLS**.
- Usuario/contraseña: `ana` / `ana`.

Capturar la conexión y el listado de `/var/www/html` como
`09-filezilla-ana.png`.

## 10. Subida de `ana`

Subir `prueba-ana.html` a `/var/www/html` y capturar el resultado como
`10-subida-ana.png`.

Comprobar en el servidor:

```bash
ls -l /var/www/html/prueba-ana.html
```

Debe mostrar grupo `webpublish` y permisos `0664` aproximadamente.

## 11. Publicación servida por Apache

```bash
curl -fsS http://www.raul.test/prueba-ana.html
```

Guardar como `11-publicacion-apache.png` y, si se quiere, una captura del
navegador como `11b-navegador-publicacion.png`.

## 12. Usuario `juan` y chroot

En FileZilla con `juan` / `juan`, capturar como `12-filezilla-juan.png`:

- El directorio inicial es `/`.
- Al intentar subir un nivel no se puede salir.

## 13. Acceso anónimo rechazado

Intentar conectar con `anonymous` y capturar el error como
`13-anonymous-rechazado.png`.

---

## Consejos para las capturas

- Usa una terminal con fuente legible y maximizes la ventana.
- Oculta contraseñas o tokens antes de guardar la imagen.
- Mantén los nombres de archivo propuestos para que encajen con la memoria.
- Las imágenes se suben dentro de `docs/capturas/` respetando la estructura.
