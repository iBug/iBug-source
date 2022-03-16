---
# a-youth-s-first-ldap-server
title: "Centralized Linux authentication with OpenLDAP"
tags: linux server ldap
redirect_from: /p/50
---

LDAP, ~~the #1 way to get your graduation delayed~~ (as has always been the meme around Tsinghua University), is every SysAdmin's dream tool for their servers. As mighty as its rumors fly, LDAP takes the most serious dedication to set up and maintain, ~~yet the slightest agitation to fail.~~

The correct story behind this opens up with our lab's messy machine management. While home directories across machines are shared from a common NFS server, user and group information is managed manually. To start with, whenever someone joins our lab, the other admin (thankfully not yet me) creates a user for them on *every* machine they'd access, while paying attention to the consistency of UID and GID. What's worse, we often grant temporary access to a selected set of machines to guest students to enable them to work on certain projects, or to participate in competitions on behalf of our lab. Not to mention the other admin himself has literally 5 different UIDs on different hosts.

LDAP solves this agony and ~~saves a lot of sysadmins' lives~~ by providing centralized management to users, groups and some other organizational resources using a directory-structured database. While I previously used an existing GOsa² setup for simple management tasks, our lab's new cluster provides an excellent opportunity to try out LDAP anew.

## Prerequisites

Thanks to a network outage a few days ago, I get to reinstall our NFS server into Proxmox VE (yes again) to allow more specialized applications to be deployed in a more flexible manner. So I can just launch a new Debian Bullseye (11) virtual machine and begin this journey. The rest of this blog post assumes this environment.

## Interlude: 389 Directory Server {#389ds}

A friend recommended Fedora's [389 Directory Server][389ds] after learning that I wanted to set up some LDAP server, indicating that it's easier to use and maintain.

So I followed the documentation and got a 389DS up and running. Everything looked simple and straightforward until I went on configuring TLS certificates. I created a self-signed certificate with extra Subject Alternative Names (as needed) and tried to import them to 389DS. [Their documentation on this][389ds-cert] is completely unhelpful, and I struggled for two tedious hours before landing on [Red Hat's documentation][rhds-cert] that actually worked. 389DS's default "group" object doesn't support POSIX GID, either.

All those failures led to one question: Why bother with 389DS when it still uses `slapd` behind? So I ditched this VM and gave it up.

## Server setup {#server}

Installation is easy:

```shell
apt install slapd
```

This installs the OpenLDAP server with all recommended packages that'll aid configuration. During installation, you'll be prompted for the admin password. Ignore that for now as we'll (probably) have to reconfigure this later.

This is because slapd tries to automatically determine the base Distinguished Name for the server, which often fails and falls back to the unpleasant `dc=nodomain`.

Run `dpkg-reconfigure slapd` to specify a domain name that will be used to derive the base DN from. It's perfectly fine to have a short name like just `ibug`, or you can choose to be serious on this and use `example.com`. Either way, you probably don't want to have a long DN like `dc=protonlab,dc=research,dc=google,dc=com`, which will make manual querying a nightmare.

Now we have an empty OpenLDAP server. The admin user's DN is `cn=admin` followed by your base DN, so most data manipulation tasks require the role to be bound to `cn=admin,dc=ibug` for me.

The additional package `ldap-utils` provides tools like `ldapadd`, `ldapmodify` and `ldapdelete` which we'll be mostly using later. `slapd` provides `slapcat` that dumps the whole database and `ldapvi` provides an interactive editor, both of which come in handy for management and debugging.

### Configuring LDAP tools {#ldap-utils}

All interactions with the server are done through `ldap*` commands submitting text in LDIF (LDAP Data Interchange Format).

Before moving on to the next step, there are config files for common settings that simplifies later tasks.

Open `/etc/ldap/ldap.conf` (the system-wide settings) and set these options:

```text
BASE    dc=ibug
URI     ldapi:///
```

There are 3 ways to connect to an LDAP server

- `ldap://` (plaintext TCP, default port 389)
- `ldaps://` (over SSL/TLS, default port 636)
- `ldapi://` (over IPC, or Unix domain socket, usually `/var/run/slapd/ldapi`)

Once you have this file set up, you can omit the `-H <host>` option from all `ldap*` commands. Similarly, `BASE` is useful in `ldapsearch` or like.

### Populating the database {#seeding}

Now that we have an empty database, we can create two directories for our users and groups. This is the first LDIF file to have.

```yaml
dn: ou=user,dc=ibug
objectClass: organizationalUnit
ou: user

dn: ou=group,dc=ibug
objectClass: organizationalUnit
ou: group
```

Use `ldapadd -D cn=admin,dc=ibug -W -f base.ldif` to load the "change request" into the database.

### Managing users and groups {#users-and-groups}

Now create the first user and group:

```yaml
dn: uid=ibug,ou=user,dc=ibug
objectClass: posixAccount
objectClass: shadowAccount
objectClass: inetOrgPerson
cn: iBug
sn: iBug
uid: ibug
uidNumber: 1000
gidNumber: 1000
homeDirectory: /home/ibug
loginShell: /bin/bash
gecos: iBug

dn: cn=staff,ou=group,dc=ibug
objectClass: posixGroup
cn: staff
gidNumber: 1000
description: My staff group
```

For user objects, `inetOrgPerson` is a required "object class", and therefore the `cn` and `sn` fields. Linux uses `posixAccount` and `shadowAccount` for authentication, and the `gecos` field is the one that'll appear in output from commands like `getent passwd`.

To add a user to a group, use `ldapmodify` with this LDIF file:

```yaml
dn: cn=staff,ou=group,dc=ibug
changetype: modify
add: memberUid
memberUid: ibug
```

Similarly, to change user information, just use `replace` with `changetype: modify`:

```yaml
dn: cn=staff,ou=group,dc=ibug
changetype: modify
replace: gecos
gecos: New iBug
```

If you're importing users and groups from an existing system, you may find the ability to preload the group with an initial set of users useful. When creating the group, you may supply any number of `memberUid`s. This has the same effect as adding them one by one.

```yaml
dn: cn=staff,ou=group,dc=ibug
objectClass: posixGroup
cn: staff
gidNumber: 1000
description: My staff group
memberUid: ibug
memberUid: user1
memberUid: user2
memberUid: user3
memberUid: user4
```

Last but not least, `ldappasswd` sets or resets passwords for users:

```shell
ldappasswd -D cn=admin,dc=ibug -W uid=ibug,ou=group,dc=ibug
```

If you don't give the new password, `ldappasswd` will generate a random new one for you, which you can forward to the user themself.

### Importing passwords from Linux {#import-passwords}

One great concern while migrating my lab's authentication completely onto LDAP was whether users can keep their passwords. LDAP uses another hashing scheme SSHA by default, while any supported hashing scheme may be imported.

By default, modern Linux stores hashed user password in `/etc/shadow`, which is only accessible by root. It contains lines like this:

```text
root:$y$j9T$egdUbc2x4FiVY42xxEH4z.$OJA25VwJ2fIEZizIqUDkS/yUtz8z5tuRiSS3XLum/F3:19064:0:99999:7:::
```

The 2nd field, delimited by colons, is the hashed password in [Bcrypt][bcrypt] format. To import that into LDAP, prepend the hash with `{CRYPT}`, like this:

```yaml
dn: uid=ibug,ou=group,dc=ibug
changetype: modify
replace: userPassword
userPassword: {CRYPT}$y$j9T$egdUbc2x4FiVY42xxEH4z.$OJA25VwJ2fIEZizIqUDkS/yUtz8z5tuRiSS3XLum/F3
```

It will be replaced with LDAP's default password hash type when the user changes their password for the next time.

Now that we have our server set up and running, it's time to configure client machines to use it.

## Client setup {#client}

There are two options for clients: More commonly `libnss-ldapd` and `libpam-ldapd` are used together, or `sssd` if you're familiar with it (which will not be described in this post). Note that are two old packages `libnss-ldap` and `libpam-ldap` (both missing the final `d`) that might confuse you.

Start with `apt install libnss-ldapd libpam-ldapd`. You'll be asked for the LDAP server and the base DN, then "name services to configure". Select `passwd group shadow` for now.

![Configure libnss-ldapd](/image/linux/libnss-ldapd.png)

These two packages should also pull in `nscd` (Name Service Cache Daemon) and `nslcd` (Name Service LDAP Client Daemon). The former provides a local cache for name service lookup results, while the latter provides the ability to lookup items from an LDAP server.

If the LDAP server is configured correctly (for `nslcd`), you should now be able to see LDAP users in the output of `getent passwd`, as well as `getent group`. LDAP users can also login via SSH or ttys.

An LDAP user changes their password using the same `passwd` command, which will be stored in LDAP and immediately available to all machines connected to this LDAP server. In case it doesn't, `nscd -i passwd` and `nscd -i group` will refresh the cache and allow nslcd to pull in the latest information.

## Advanced topics {#advanced}

### Securing LDAP server with TLS {#tls}

Nothing is "baseline secure" over unencrypted traffic, so the next thing is to add TLS certificates for the LDAP server. Certificates aren't hard to get. For example, if you have a public domain, [Let's Encrypt][letsencrypt] is the easiest way to get a universally-trusted certificate. Otherwise, you can create a self-signed certificate that can include any domain name or IP address. [XCA] is one of the best tools to manage a private Certificate Authority.

Copy the certificate and private key files to the `/etc/ldap/` directory. Change the owner and group to `openldap` and file mode to `0644` (for the certificate) or `0400` (for the private key). This ensures only the OpenLDAP server can access them. Now you need to tell the server to *use* these files.

### Managing permissions {#permissions}

### Allow users to change login shell {#user-chsh}

## References

- [使用 OpenLDAP 在 Linux 上进行中心化用户管理 - Harry Chen's blog](https://harrychen.xyz/2021/01/17/openldap-linux-auth/)

  [389ds]: https://directory.fedoraproject.org/
  [389ds-cert]: https://directory.fedoraproject.org/docs/389ds/howto/howto-ssl-archive.html#importing-an-existing-self-sign-keycert-or-3rd-party-cacert
  [rhds-cert]: https://access.redhat.com/documentation/en-us/red_hat_directory_server/11/html/administration_guide/managing_the_nss_database_used_by_directory_server
  [bcrypt]: https://en.wikipedia.org/wiki/Bcrypt
  [letsencrypt]: https://letsencrypt.org/
  [xca]: https://hohnstaedt.de/xca/
