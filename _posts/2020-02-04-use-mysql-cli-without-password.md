---
title: "3 ways to use MySQL / MariaDB CLI without password"
tags: linux mysql
redirect_from: /p/34
---

For all of us who are learning to use or developing with MySQL or MariaDB, it's a common task to manually log in to the database for inspection. This is usually done with the `mysql` command line client, and for sure it's cumbersome to log in to the database using your application's credentials. For convenience purposes, you would like to make your life easy by configuring the `mysql` CLI to **NOT** prompt you for a password each time. Here are three ways to do it on Linux.

(This may work on BSD and macOS as well, but I haven't tested.)

## Method 1: Use `sudo`

By default, the local root user can log in to MySQL or MariaDB without password, so you can just use `sudo mysql` instead of `mysql`, and expect everything to work. Of course, this depends on your `sudo` to not ask you for a password, or you'll still have to enter one for the root privilege.

You can go one step further by adding `alias mysql='sudo mysql'` to your `.bashrc` or whatever shell you're using, but this is still a bit hackish, and IMO is more a workaround than a solution, so read on before proceeding.

## Method 2: Use a password and remember it somewhere

The second option is to use a password, and let it be "automatically supplied" in some other way.

First, create a database user for yourself. Don't forget to replace `ibug` with your username.

```sql
CREATE USER 'ibug'@'localhost' IDENTIFIED BY 'some_password';
GRANT ALL PRIVILEGES ON *.* TO 'ibug'@'localhost';
FLUSH PRIVILEGES;
```

Now you can log in to MySQL or MariaDB using `mysql -uibug -p'some password'`.

You're probably urged to add that as an alias in your `.bashrc`, but hold on again, that's the wrong way to do it. In case your `.bashrc` is readable by others, you risk exposing your password. Also, in case you want to log in as another user some time later, you may mess things up because of the alias expansion.

The correct way to store the password for yourself is to write it in a file named `.my.cnf` under your home directory. Its content should look like this:

```ini
[client]
user=ibug
password=some_password
```

Remember to `chmod 600` on it so no one else reads it. You can now try running `mysql` directly, and it'll read your username and password from `.my.cnf` without prompting you for anything.

But again, if you use a weak password and someone manages to guess it, you still risk exposing your whole MySQL database to them.

Think how the root user on your system logs in to MySQL directly - it's safe and secure, because you can't log in without password using the root user (unless you're running `mysql` as root, but not `mysql -uroot -p` as a regular user). The good news is, *you* can replicate this setup for yourself! So read on for the last and perfect solution.

## Method 3: Use Unix authentication

A bit of background first. Like how one can get the address and port of other end of a TCP or UDP socket, one can also get the connector information of the other end of a unix socket, namely, the process ID, user ID and group ID (see [`man 7 unix`][unix.7], look for `SCM_CREDENTIALS`).

When you run `mysql` on your local machine, it will try to connect to the MySQL server using a unix socket located at `/var/run/mysqld/mysqld.sock`, and this way the MySQL server will know who it is trying to connect. This is exactly how MySQL identifies the local root user: The root user won't have the same access if it tries connecting via TCP (i.e. `mysql -h 127.0.0.1`).

To let MySQL recognize you using unix socket magic, you can use the following query to create your user:

```sql
CREATE USER 'ibug'@'localhost' IDENTIFIED WITH auth_socket;
```

If you have already created a user, you can change its authentication method by simply replacing `CREATE` with `ALTER` in the above query:

```sql
ALTER USER 'ibug'@'localhost' IDENTIFIED WITH auth_socket;
```

<div class="notice--primary" markdown="1">
### <i class="fas fa-exclamation-circle"></i> MariaDB makes a difference here!

[MariaDB][mariadb], a community fork of Oracle MySQL, uses a similar query for unix socket authentication:

```sql
CREATE USER 'ibug'@'localhost' IDENTIFIED VIA unix_socket;
--                                        ^^^^^^^^^^^^^^^
```

Better yet, MariaDB supports user creation with `GRANT` query, so the first two queries can be merged into one:

```sql
GRANT ALL PRIVILEGES ON *.* TO 'ibug'@'localhost' IDENTIFIED VIA unix_socket;
```
</div>

After the user is set up properly, use the same `GRANT` query to grant access to yourself.

Now you can use `mysql` to manage your whole database without being prompted for password. You can safely delete `.my.cnf` if you created it following Method 2 and you don't have other options in it. You can also try using `mysql -u<your username>` under another user and see it fail, to ensure that only *you* can access the database directly.

## <i class="fas fa-lightbulb"></i> Creating and granting access to more users

If you want to create more users with your `mysql` command line, you'll probably see this message:

```text
ERROR 1045 (28000): Access denied for user 'ibug'@'localhost' (using password: YES)
```

This is because you haven't granted yourself *the privilege to grant*, or in other words, your privilege isn't "redistributable".

You can set the privileges again, but with the privilege to "redistribute" your access to more users, with the following query:

```sql
GRANT ALL PRIVILEGES ON *.* TO 'ibug'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
```

Similarly, the one-liner for MariaDB looks like this:

```sql
GRANT ALL PRIVILEGES ON *.* TO 'ibug'@'localhost' IDENTIFIED VIA unix_socket WITH GRANT OPTION;
FLUSH PRIVILEGES;
```

Both MySQL and MariaDB requires "flushing" after any privilege assignment is altered.

You can then create more users with your passwordless access, and play around with MySQL to fulfill your curiosity.

And that concludes this tutorial. Cheers!

## Bonus: Use Docker

If you're looking for an isolated MySQL or MariaDB installation to experiment with (particularly if you're taking on a database course), Docker has always been around as a good isolation platform.

If you haven't got Docker already, their official guide on installing on [Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/) (and [Debian](https://docs.docker.com/install/linux/docker-ce/debian/), [CentOS](https://docs.docker.com/install/linux/docker-ce/centos) and [Fedora](https://docs.docker.com/install/linux/docker-ce/fedora/)) is available.

After getting Docker ready, spin up a container with the official image [mysql](https://hub.docker.com/_/mysql) or [mariadb](https://hub.docker.com/_/mariadb):

```shell
docker run -d mysql:latest
```


  [unix.7]: http://man7.org/linux/man-pages/man7/unix.7.html "unix(7)"
  [mariadb]: https://en.wikipedia.org/wiki/MariaDB
