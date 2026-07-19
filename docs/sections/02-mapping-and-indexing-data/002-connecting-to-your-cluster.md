---
title: "2. Connecting to your Cluster"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 02</div>

# 2. Connecting to your Cluster

With Elasticsearch running in a virtual machine, the realistic way to work with it is the same way you would work with a real remote cluster: **connect over SSH**. Signing into the VM's console directly works, but in the real world your cluster lives on remote servers — so this chapter sets up the SSH workflow used before every hands-on exercise.

## Step 1 — Forward the ports in VirtualBox

The VM's services need to be reachable from the host machine. In VirtualBox Manager, select your Elasticsearch VM → **Settings → Network → Port Forwarding**, and add three rules:

| Rule | Host IP | Host port | Guest port | Purpose |
| --- | --- | --- | --- | --- |
| ssh | 127.0.0.1 | 22 | 22 | Secure shell access |
| elasticsearch | 127.0.0.1 | 9200 | 9200 | The Elasticsearch REST API |
| kibana | 127.0.0.1 | 5601 | 5601 | The Kibana web UI (used later) |

> If you are on macOS or Linux and port 22 is already in use by your host's own SSH service, pick another host port (e.g. 2222) — just remember to use it when connecting.

## Step 2 — Install an SSH server in the VM

The **desktop** version of Ubuntu does not run an SSH server by default (the server version usually does). In a terminal inside the VM:

```bash
sudo apt-get install openssh-server
sudo systemctl enable ssh
```

## Step 3 — Create a user to log in with

Create a dedicated account for remote work and give it sudo rights:

```bash
sudo adduser student        # pick a password you won't forget
sudo usermod -aG sudo student
```

## Step 4 — Connect from your desktop

**Windows:** there is no built-in Linux-friendly terminal client in the classic setup, so download **PuTTY** from [putty.org](https://putty.org). Enter host name `127.0.0.1`, port `22`, save the session under a name like "elasticsearch" for reuse, and click *Open*. Accept the one-time host-key security warning, then log in as `student`. PuTTY also gives you convenient copy/paste with the Windows clipboard.

**macOS / Linux:** use the built-in terminal:

```bash
ssh student@127.0.0.1 -p 22
```

Answer *yes* to the first-time host-key prompt and enter your password.

> **Note:** Modern Windows 10/11 ships OpenSSH in PowerShell/Terminal, so the `ssh` command above works there too — PuTTY is simply the classic choice.

## Why bother?

You could use the VM's graphical terminal directly. The SSH route mirrors the real-world situation — a server edition of Ubuntu running remotely that you administer over SSH — and that is the habit worth building. Remember this workflow: **every exercise from here on starts by SSHing into the cluster.**

## Key takeaways

- Port-forward 22 (SSH), 9200 (Elasticsearch), and 5601 (Kibana) from the host to the VM.
- Desktop Ubuntu needs `openssh-server` installed and enabled; server Ubuntu usually has it already.
- Connect with PuTTY (Windows) or `ssh student@127.0.0.1` (macOS/Linux/modern Windows).

<div class="chapter-nav">
<a class="chapter-nav__item" href="001-intro.html"><span>Previous</span><strong>1. Introduction</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="003-introducing-the-movielens-data-set.html"><span>Next</span><strong>3. Introducing the MovieLens Data Set</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 2</a></p>
