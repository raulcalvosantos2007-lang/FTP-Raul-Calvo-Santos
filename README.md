# Memoria de la práctica: Servidor FTP seguro con Vagrant y Ansible

**Asignatura:** Despliegue de Aplicaciones Web (DAW), 2.º curso  
**Alumno:** Raul Calvo Santos  
**Dominio usado:** `raul.test`  
**Repositorio:** `FTP-Raul-Calvo-Santos`  
**Fecha:** noviembre de 2026

Este README documenta **lo que se ha hecho**: los archivos que se han creado,
las decisiones tomadas y las comprobaciones que se han podido realizar en el
entorno de trabajo. No es un manual de lo que habría que hacer.

> **Estado real de la práctica:** se ha elaborado y validado localmente todo el
> proyecto (infraestructura, playbooks, zonas DNS, configuración de FTP,
> memoria y diagramas). En este entorno **no se han arrancado las máquinas
> virtuales ni se han ejecutado los playbooks**, por lo que tampoco hay
> capturas reales de esas ejecuciones. Los scripts de prueba y la lista de
> capturas están preparados para cuando se ejecute en un nodo con Vagrant y
> Ansible.

---

## 1. Objetivo abordado

Se ha diseñado un entorno reproducible, definido como código, para un servidor
FTP seguro sobre un dominio propio (`raul.test`), cubriendo los puntos que pide
el enunciado: infraestructura con Vagrant, aprovisionamiento con Ansible, DNS
propio, servidor web, usuarios FTP locales, restricciones de acceso y cifrado
TLS de las transferencias.

El nombre del alumno se ha aplicado donde el enunciado lo exige: dominio
`raul.test`, nombre de zona `db.raul.test`, hostname `dns.raul.test` y
`negocio.raul.test`, certificado `ftp.raul.test`, directorio de certificados
`/etc/ssl/raul` y autoría de la licencia y la memoria. No se ha cambiado la
palabra «equipo» cuando significa *ordenador anfitrión*.

## 2. Entorno que se ha definido

| Máquina   | Nombre configurado  | IP             | Servicio previsto             |
|-----------|---------------------|----------------|-------------------------------|
| `dns`     | `dns.raul.test`     | `192.168.57.5` | BIND 9                        |
| `negocio` | `negocio.raul.test` | `192.168.57.7` | Apache 2 y vsftpd sobre TLS   |

Alias creados en la zona directa: `raul.test` y `negocio.raul.test` apuntan a
`192.168.57.7`; `www.raul.test` y `ftp.raul.test` son CNAME de
`negocio.raul.test`.

## 3. Archivos creados y qué contiene cada uno

### 3.1. Base del repositorio

| Archivo | Contenido real |
|---|---|
| `.gitattributes` | Forzar saltos de línea LF y marcar como ejecutables los scripts `.sh`. |
| `.gitignore` | Excluir `.vagrant/`, `*.retry`, `vault.yml` sin cifrar y archivos temporales. |
| `LICENSE` | Licencia MIT con copyright de 2026 Raul Calvo Santos. |
| `inventory.yml` | Inventario YAML con los alias `dns` (192.168.57.5) y `negocio` (192.168.57.7). |
| `ansible.cfg` | `remote_user = vagrant`, clave insegura de Vagrant, `host_key_checking = False`, `interpreter_python = auto_silent` e inventario por defecto. |

### 3.2. Infraestructura

`Vagrantfile`:

- Imagen base `debian/bookworm64` para las dos VM.
- `config.ssh.insert_key = false` para conservar la clave insegura de Vagrant
  durante la práctica.
- Definición de `dns.raul.test` en `192.168.57.5` y de
  `negocio.raul.test` en `192.168.57.7`, ambas en red privada.

### 3.3. Servidor DNS

`dns/dns.yml`:

- Instala `bind9`.
- Copia `named.conf.options`, `named.conf.local`, `db.raul.test` y
  `db.192.168.57` a sus rutas del sistema.
- Valida la configuración con `named-checkconf` y las dos zonas con
  `named-checkzone`.
- Habilita `bind9` y usa un *handler* para reiniciarlo solo cuando cambian los
  archivos.

Archivos de zona creados:

| Archivo | Registros escritos |
|---|---|
| `dns/files/named.conf.local` | Zona directa `raul.test` e inversa `57.168.192.in-addr.arpa`. |
| `dns/files/named.conf.options` | Opciones de BIND con recursión limitada a la red privada. |
| `dns/files/db.raul.test` | SOA, NS, A para `dns`, `negocio` y la raíz, y CNAME `www` y `ftp`. |
| `dns/files/db.192.168.57` | SOA, NS y PTR para `192.168.57.5` y `192.168.57.7`. |

`dns/test-dns.sh`: script con las comprobaciones de resolución directa e
inversa, con salida `OK`/`ERROR`.

### 3.4. Servidor web

`web/web.yml` instala `apache2`, copia `web/files/index.html` a
`/var/www/html/index.html`, habilita el servicio y define un *handler* de
reinicio. La página creada contiene el texto `Servidor web de raul.test`,
que es el que busca `web/test-web.sh` con `curl`.

### 3.5. Servidor FTP

`ftp/ftp.yml`:

- Instala `vsftpd` y `python3-cryptography`.
- Crea los grupos `ftpusers` y `webpublish`.
- Crea los usuarios `juan` y `ana` con hashes SHA-512 tomados de
  `vars/vault.yml`.
- Añade `ana` a `webpublish` y deja `/var/www/html` con grupo `webpublish` y
  modo `2775` (bit setgid).
- Escribe `/etc/vsftpd.chroot_list` solo con `ana`, de forma que `juan` queda
  enjaulado.
- Crea `/etc/vsftpd_user_conf/ana` con `local_root=/var/www/html` y
  `write_enable=YES`.
- Genera clave RSA de 2048 bits, CSR y certificado autofirmado de un año con
  `community.crypto`, con `CN=ftp.raul.test` y SAN `DNS:ftp.raul.test`, en
  `/etc/ssl/raul`.
- Copia `files/vsftpd.conf` a `/etc/vsftpd.conf`, habilita `vsftpd` y
  reinicia el servicio mediante un *handler*.

`ftp/files/vsftpd.conf` contiene las decisiones de seguridad tomadas:

| Opción | Valor escrito | Finalidad |
|---|---|---|
| `listen` / `listen_ipv6` | `YES` / `NO` | Servicio independiente solo en IPv4. |
| `anonymous_enable` | `NO` | Sin acceso anónimo. |
| `local_enable` / `write_enable` | `YES` / `YES` | Solo usuarios locales con permiso de subida. |
| `local_umask` / `file_open_mode` | `002` / `0666` | Archivos nuevos `0664`, legibles por Apache. |
| `chroot_local_user` | `YES` | Jaulas por defecto. |
| `chroot_list_file` | `/etc/vsftpd.chroot_list` | Excepción para `ana`. |
| `user_config_dir` | `/etc/vsftpd_user_conf` | Configuración particular de `ana`. |
| `ssl_enable`, `force_local_logins_ssl`, `force_local_data_ssl` | `YES` | FTP explícito sobre TLS obligatorio. |
| `require_ssl_reuse` | `NO` | Compatibilidad con FileZilla. |
| `ssl_tlsv1`, `ssl_tlsv1_1`, `ssl_sslv2`, `ssl_sslv3` | `NO` | Rechazo de protocolos antiguos. |
| `rsa_cert_file` / `rsa_private_key_file` | `/etc/ssl/raul/vsftpd.crt` / `.key` | Certificado generado por Ansible. |
| `pasv_min_port` / `pasv_max_port` / `pasv_address` | `40000` / `40100` / `192.168.57.7` | Rango pasivo y dirección anunciada. |

`ftp/vars/vault.yml.example` guarda los hashes SHA-512 de las contraseñas de
práctica de `juan` y `ana`, generados con `mkpasswd --method=sha-512`. El
archivo real `vault.yml` no se ha incluido: debe crearse y cifrarse con
`ansible-vault` antes de ejecutar el playbook.

`ftp/PRUEBAS.md` recoge las siete comprobaciones previstas del servicio FTP:
certificado TLS, rechazo de `anonymous`, chroot de `juan`, publicación de
`ana`, negociación TLS, pruebas con `curl` y tabla de resultados esperados.

### 3.6. Documentación generada

| Archivo | Contenido |
|---|---|
| `README.md` | Esta memoria de lo realizado. |
| `docs/MEMORIA.md` | Memoria detallada: objetivo, arquitectura, herramientas, desarrollo de cada bloque, tablas DNS y vsftpd, seguridad y conclusión. |
| `docs/diagrama-arquitectura.svg` | Diagrama original con las dos VM, IPs, servicios y flujo Vagrant/Ansible/DNS/HTTP/FTP. |
| `docs/diagrama-publicacion.svg` | Diagrama original del flujo de subida de `ana`, lectura por Apache, chroot de `juan` y rechazo de `anonymous`. |
| `docs/capturas/README.md` | Lista de 13 capturas a obtener, con comando y resultado esperado para cada una. |
| `docs/github.md` | Guía de repositorio, Projects e issues. |
| `docs/SUBIDA_GITHUB.md` | Lista de archivos, comandos de subida y pasos de GitHub. |

Los dos SVG son imágenes creadas para el proyecto. **No se han inventado
capturas de ejecución**: la carpeta `docs/capturas/` solo contiene el listado
de las que deben tomarse.

## 4. Comprobaciones que sí se han realizado

| Comprobación | Resultado obtenido |
|---|---|
| Sintaxis del `Vagrantfile` | `vagrant validate` terminó correctamente. |
| Sintaxis de los dos diagramas SVG | Analizados como XML sin errores. |
| Dominio en los archivos | 0 apariciones de `equipo.test`; 81 de `raul.test`. |
| Estado del repositorio local | Árbol de trabajo limpio. |
| Historial | 26 commits, uno por archivo, con fecha y hora reales. |
| Carpeta de entrega `Raúl/` | 26 archivos con la estructura final. |

## 5. Estado de lo que queda fuera de este entorno

Estas acciones **no se han realizado aquí** y, por tanto, no se documentan como
hechas:

- Arranque de las VM (`vagrant up`) y ejecución de `ansible-playbook`.
- Creación y cifrado del `ftp/vars/vault.yml` real.
- Obtención de capturas de terminal, FileZilla o navegador.
- Creación del repositorio remoto, del tablero de GitHub Projects, de las
  issues y añadido de `frayaIzv` como colaborador.

La carpeta `Raúl/` y el historial local están preparados para que esos pasos se
hagan desde tu propia cuenta de GitHub.

## 6. Estructura final entregada

```text
Raúl/
├── .gitattributes
├── .gitignore
├── LICENSE
├── README.md
├── Vagrantfile
├── ansible.cfg
├── inventory.yml
├── dns/
│   ├── dns.yml
│   ├── test-dns.sh
│   └── files/
│       ├── named.conf.options
│       ├── named.conf.local
│       ├── db.raul.test
│       └── db.192.168.57
├── web/
│   ├── web.yml
│   ├── test-web.sh
│   └── files/
│       └── index.html
├── ftp/
│   ├── ftp.yml
│   ├── PRUEBAS.md
│   ├── files/
│   │   └── vsftpd.conf
│   └── vars/
│       └── vault.yml.example
└── docs/
    ├── MEMORIA.md
    ├── SUBIDA_GITHUB.md
    ├── github.md
    ├── diagrama-arquitectura.svg
    ├── diagrama-publicacion.svg
    └── capturas/
        └── README.md
```

## 7. Autor y licencia

Raul Calvo Santos — 2.º DAW. El proyecto se distribuye bajo licencia MIT
(`LICENSE`).
