# 📧 Catch-All Docker Mail Server (Red Team Infrastructure)

![Docker](https://img.shields.io/badge/Docker-Enabled-blue.svg) ![Security](https://img.shields.io/badge/Status-Offensive_Ready-red.svg) ![License](https://img.shields.io/badge/License-MIT-green.svg)

[🇺🇸 English Version](README.md) | [🇧🇷 Versão Português](README_PTBR.md)

## 💀 Propósito

Este projeto fornece um **Servidor de Email Catch-All Dockerizado**, desenhado para operações de Segurança Ofensiva, engajamentos de Red Team e investigações OSINT.

Ele captura **TODOS** os emails enviados para qualquer usuário em seu domínio (`*@seudominio.com`) e os entrega em uma única caixa de entrada. Isso é crítico para:

-   **Campanhas de Engenharia Social**: Receber respostas de múltiplos aliases de phishing sem gerenciar contas individuais.
-   **Registro de Contas**: Criar múltiplas contas em plataformas alvo usando endereços de email únicos (ex: `admin@seudominio.com`, `suporte@seudominio.com`) que roteiam para o mesmo lugar.
-   **Infraestrutura C2**: Receber callbacks ou exfiltração de dados via SMTP.
*Nota: Não faz o envio de emails, apenas o recebimento.*

## 🚀 Funcionalidades

-   **Dockerizado**: Zero poluição no sistema host. Sobe em segundos.
-   **Catch-All Wildcard**: Roteamento baseado em Regex (`/@exemplo\.com$/ -> inbox`).
-   **SSL/TLS Completo**: Certificados Let's Encrypt automatizados (via Docker Certbot).
-   **Protocolos Padrão**:
    -   **IMAP (993)**: Compatível com Outlook, Thunderbird, eM Client.
    -   **SMTP (587)**: Submissão segura para envio de respostas.
-   **Resiliente**:
    -   Usa Postfix + Dovecot (Padrão da Indústria).
    -   Inclui fallback `luser_relay` para máxima confiabilidade.
    -   **Rede Host/Bridge**: Configurável para suportar NAT corretamente e visibilidade de IP real.

## 🛠 Pré-requisitos

-   **Servidor Linux** (Debian/Ubuntu recomendado) ou Windows (WSL2).
-   **Docker** & **Docker Compose**.
-   **Portas**: 80 (para Certbot), 25, 587, 143, 993 disponíveis.
-   **Domínio** configurado com registros DNS.

## 📡 Configuração de DNS (Crítico)

Antes de rodar o servidor, configure estes registros no seu provedor de DNS (Cloudflare, Namecheap, etc.).
*Nota: Se usar Cloudflare, use "DNS Only" (Nuvem Cinza) para o registro `mail`.*

| Tipo | Nome | Conteúdo | Propósito |
| :--- | :--- | :--- | :--- |
| **A** | `mail` | `<SEU-IP-DO-SERVIDOR>` | Aponta servidores remotos para sua máquina. |
| **MX** | `@` | `mail.seudominio.com` (Prioridade 10) | Roteia emails para seu servidor. |
| **TXT** | `@` | `v=spf1 mx -all` | **Registro SPF**: Autoriza seu servidor a enviar email. |
| **A** | `catchall` | `<SEU-IP-DO-SERVIDOR>` | (Opcional) Se você usa um subdomínio específico para auth. |

> **Dica Pro:** Configure um registro **PTR (Reverso)** para o seu IP no provedor do VPS para melhorar a entregabilidade e evitar filtros de spam durante engajamentos ativos.

## ⚡ Deploy

1.  **Clone/Baixe** este repositório.
2.  **Execute o orquestrador**:

    ```bash
    chmod +x start.sh
    sudo ./start.sh
    ```

3.  **Siga as instruções**:
    -   **Domínio**: `seudominio.com`
    -   **Hostname**: `mail.seudominio.com`
    -   **Usuário**: `inbox` (O usuário do sistema que recebe tudo)
    -   **Senha**: Defina uma senha forte.

O script irá automaticamente:
-   Gerar certificados SSL (se faltarem).
-   Configurar Postfix/Dovecot.
-   Iniciar o container.

## 🔌 Configuração do Cliente (Outlook / Thunderbird)

Configure seu cliente de email para acessar o loot:

-   **Endereço de Email**: `inbox@seudominio.com` (Ou `qualquercoisa@seudominio.com`, vai para o mesmo lugar).
-   **Usuário**: `inbox@seudominio.com`
-   **Senha**: `<Senha definida no start.sh>`
-   **Servidor de Entrada (IMAP)**:
    -   Hostname: `mail.seudominio.com` (ou seu registro A)
    -   Porta: **993**
    -   Criptografia: **SSL/TLS**
-   **Servidor de Saída (SMTP)**:
    -   Hostname: `mail.seudominio.com`
    -   Porta: **587**
    -   Criptografia: **STARTTLS** (ou Auto)

## 📂 Estrutura do Projeto

```text
.
├── start.sh            # Orquestrador (Execute este!)
├── config/             # Configs Postfix/Dovecot (Geradas)
├── mail_data/          # Armazenamento persistente de emails
├── letsencrypt/        # Certificados SSL
└── Dockerfile          # Definição da imagem do servidor
```

---
*Aviso Legal: Esta ferramenta é apenas para testes autorizados e fins educacionais. Use com responsabilidade.*
