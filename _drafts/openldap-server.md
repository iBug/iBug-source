---
title: "Youth's first OpenLDAP server"
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

### Populating the database {#seeding}

All interactions with the server are done through `ldap*` commands submitting text in LDIF (LDAP Data Interchange Format). Now that we have an empty database, we can create two directories for our users and groups. This is the first LDIF file to have.

```yaml
dn: ou=user,dc=ibug
objectClass: organizationalUnit
ou: user

dn: ou=group,dc=ibug
objectClass: organizationalUnit
ou: group
```

Use `ldapadd -D cn=admin,dc=ibug -W -f base.ldif` to load the "change request" into the database.

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
```

```yaml
dn: cn=staff,ou=group,dc=ibug
objectClass: posixGroup
cn: staff
gidNumber: 1000
description: My staff group
```

To add a user to a group, use `ldapmodify` with this LDIF file:

```yaml
dn: cn=staff,ou=group,dc=ibug
changetype: modify
add: memberUid
memberUid: ibug
```

## References

- [使用 OpenLDAP 在 Linux 上进行中心化用户管理 - Harry Chen's blog](https://harrychen.xyz/2021/01/17/openldap-linux-auth/)

  [389ds]: https://directory.fedoraproject.org/
  [389ds-cert]: https://directory.fedoraproject.org/docs/389ds/howto/howto-ssl-archive.html#importing-an-existing-self-sign-keycert-or-3rd-party-cacert
  [rhds-cert]: https://access.redhat.com/documentation/en-us/red_hat_directory_server/11/html/administration_guide/managing_the_nss_database_used_by_directory_server
