# SSH authentication on Cloudogu EcoSystem

## Introduction

The Cloudogu EcoSystem (CES) is based on Ubuntu 20.04 and has an active SSH server installed.
The connection to this server is only possible via the public key method; the
authentication via username/password has been disabled for security reasons. To get the
public key(s) in the machine, it is necessary to save them in an `authorized_keys` file and
mount this file inside the EcoSystem at `/etc/ces/authorized_keys`. This file is integrated
as soon as the system or the SSH daemon is rebooted.

## Creating an SSH public/private key pair

To create a public/private key pair, here are the instructions:
https://www.ssh.com/academy/ssh/keygen

## Structure of the authorized_keys file

The `authorized_keys` file is structured to contain a public key (e.g. from
the `id_rsa.pub` file from the previous step). If more than one key is to be included
they can simply be written one below the other in the file. Each line may
end with a comment, separated from the key by a space.
The `authorized_keys` file may look like this, for example:

```
ssh- rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDY0nVMmCeczF8jLAwnw3PNGMMAlqskpw8lfJuZeTIrAklIIeVqXmaHaCDbC+Z+/WYtp/5A9H8V6MDz7pMyrTCnm8g6nKZ0J/kH+kP8iT9f1d2V78AG1P3v6R19UeT8h3926bB/IJGmnzo53gnfdV+YhSEwsIGFI3ikzjc0GOZBAvhCLPo6WXAbcvM5+qVTFUjkQwi6lQBjtS/cIZJrcB9J9bLNJbait5itaXLyLy52Igt8dQbzB5hnvlBwUuFHnt0agXF0yxb+VVRzF0BVZ0rE0MKwCiG/mwbspIDOhuMj5DwtRiSC0LtNCn9V46cuDy1lrsUvO2g1mo3ptbhEAxv+UAStbDKkgSvKDfK3Q0AdLE6+AgZ/EehcRQvo10W5lY6JOm5PcHstFQLy4g660IiOrxrSN5HCZmRzeU49vT4o3tYxXsxSebxvumOmmnHlZUczZbRbEiSJ5L7RLRhQpJ4adkGuPWEyXXYsQtlgOlmBUZnEm9N8oaNIlknW5lUV4ZyRMAL7VdMgvwZDaqWgl1JZpp9Np3WKWizzuOOZm6jlZW3Sbsyr8Lw3SZXYSCU03gx+YZFGk+1zmwvtCp86i7gzH6lpami8mAHfEWVqaZoHWBlCU35gqaUscvWEJ7KMtQNCdHV8tMEE5IFSfigXgQjfsiqj6v+detsN+uN31PepxQ== SSHuser123
ssh- rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCJi7dJnW9zB3m5iakfUwmntYLahA82WqYKM3f9VQhbpwI93zBD2SPrvH02TtEVgGvyW3oR7RMVbAOf0YEe5F6GM3qxL8r1uhitrOqblDCAz8xyVz1GfWy3v+5hMXyN3/yFpTmm8QK1V9xdIKdMcxGn5CdEpMHSODs1X7CIxs2fZ2Kw4kzCOY064+wfwGpnaJhbABpNnEudLAHkphZWSB0wF0kVrcU4GJaDH8Hr9fbkc/rPChGQ9DvFNHUGdvWTSL3tDkmfSk+EdzHU1rwZxHAhGVz2SlwLGWs7zS9YrpbF7xyuOT7GhR9ZRH4Ef1fPxHjztTIbu74mC+PdPf/Odm/ john.doe@example.net
```

## Including the authorized_keys file into the EcoSystem

To include the `authorized_keys` file in the EcoSystem, follow these steps for VMware Workstation VMs:

- Create a new VM by importing the CES image.
- Mount the folder containing the `authorized_keys` file as a Shared Folder
    - See "Settings" of the VM -> "Options" tab -> "Shared Folders"
    - Enable "Shared Folders" and add the folder with a name
- Create new entry in `/etc/fstab`:
  `.host:/NameOfTheSharedFolder /etc/ces fuse.vmhgfs-fuse defaults,allow_other,uid=1000 0 0`
- Reboot the system or mount the shared folder via `sudo mount -a`.

## Troubleshooting

If the authentication via public key does not work, the logfile of the SSH service can help.
You can read it e.g. via `journalctl -u ssh`.
If there are entries like `Authentication refused: bad ownership or modes for file /etc/ces/authorized_keys`,
the file permissions should be checked and reset if necessary, e.g. via `chmod 600 /etc/ces/authorized_keys` and `chown ces-admin:ces-admin /etc/ces/authorized_keys`.