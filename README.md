# 🌾 HarvestMX - Catch-All Docker Mail Server

![Docker](https://img.shields.io/badge/Docker-Enabled-blue.svg) ![Security](https://img.shields.io/badge/Status-Offensive_Ready-red.svg) ![License](https://img.shields.io/badge/License-MIT-green.svg)

[🇺🇸 English Version](README.md) | [🇧🇷 Versão Português](README_PTBR.md)

## 💀 Purpose

**HarvestMX** is an **Automated Deployment Orchestrator** for a Dockerized Catch-All Email Server, designed for Offensive Security operations, Red Team engagements, and OSINT investigations.

It captures **ALL** emails sent to any user at your domain (`*@yourdomain.com`) and delivers them to a single inbox. This is critical for:

-   **Social Engineering Campaigns**: Receiving replies from multiple phishing aliases without managing individual accounts.
-   **Account Registration**: Creating multiple accounts on target platforms using unique email addresses (e.g., `admin@yourdomain.com`, `support@yourdomain.com`) that all route to one place.
-   **C2 Infrastructure**: Receiving callbacks or data exfiltration via SMTP.

*Note: Does not send emails, only receives them.*

## 🚀 Features

-   **Dockerized**: Zero pollution on the host system. Spins up in seconds.
-   **Wildcard Catch-All**: Regex-based routing (`/@example\.com$/ -> inbox`).
-   **Full SSL/TLS**: Automated Let's Encrypt certificates (via Certbot Docker).
-   **Standard Protocols**:
    -   **IMAP (993)**: Compatible with Outlook, Thunderbird, eM Client.
    -   **SMTP (587)**: Secure submission for sending replies.
-   **Resilient**:
    -   Uses Postfix + Dovecot (Industry Standard).
    -   Includes `luser_relay` fallback for maximum reliability.
    -   **Host Networking**: Bypasses Docker NAT issues for true IP visibility.

## 🛠 Prerequisites

-   **Linux Server** (Debian/Ubuntu recommended) or Windows (WSL2).
-   **Docker** & **Docker Compose**.
-   **Ports**: 80 (for Certbot), 25, 587, 143, 993 available.
-   **Domain Name** configured with DNS records.

## 📡 DNS Configuration (Critical)

Before running the server, configure these records at your DNS provider (Cloudflare, Namecheap, etc.).
*Note: If using Cloudflare, use "DNS Only" (Grey Cloud) for the `mail` record.*

| Type | Name | Content | Purpose |
| :--- | :--- | :--- | :--- |
| **A** | `mail` | `<YOUR-SERVER-IP>` | Points remote servers to your machine. |
| **MX** | `@` | `mail.yourdomain.com` (Priority 10) | Route emails to your server. |
| **TXT** | `@` | `v=spf1 mx -all` | **SPF Record**: Authorizes your server to send email. |
| **A** | `catchall` | `<YOUR-SERVER-IP>` | (Optional) If you use a specific sub for auth. |

> **Pro Tip:** Set up a **PTR (Reverse DNS)** record for your IP at your VPS provider to improve deliverability and avoid spam filters during active engagements.

## ⚡ Deployment

1.  **Clone/Download** this repository.
2.  **Run the orchestrator**:

    ```bash
    chmod +x start.sh
    sudo ./start.sh
    ```

3.  **Follow the prompts**:
    -   **Domain**: `yourdomain.com`
    -   **Hostname**: `mail.yourdomain.com`
    -   **User**: `inbox` (The system user that receives everything)
    -   **Pass**: Set a strong password.

The script will automatically:
-   Gerar SSL certificates (if missing).
-   Configure Postfix/Dovecot.
-   Launch the container.

## 🔌 Client Configuration (Outlook / Thunderbird)

Configure your mail client to access the loot:

-   **Email Address**: `inbox@yourdomain.com` (Or `any@yourdomain.com`, it routes to the same place).
-   **Username**: `inbox@yourdomain.com`
-   **Password**: `<Password you set in start.sh>`
-   **Incoming Server (IMAP)**:
    -   Hostname: `mail.yourdomain.com` (or your A record)
    -   Port: **993**
    -   Encryption: **SSL/TLS**
-   **Outgoing Server (SMTP)**:
    -   Hostname: `mail.yourdomain.com`
    -   Port: **587**
    -   Encryption: **STARTTLS** (or Auto)

## 📂 Project Structure

```text
.
├── start.sh            # Orchestrator (Run this!)
├── config/             # Postfix/Dovecot configs (Generated)
├── mail_data/          # Persistent email storage
├── letsencrypt/        # SSL Certificates
└── Dockerfile          # Server image definition
```

---
*Disclaimer: This tool is for authorized testing and educational purposes only. Use responsibly.*

