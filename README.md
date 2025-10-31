# BeDeli - Sistema de Acompanhamento de Entregas em Tempo Real

[![Status do Projeto](https://img.shields.io/badge/status-em%20desenvolvimento-yellow)](https://github.com/JoaoVieiraZP/BeDeli.git)

Um sistema completo de logística e acompanhamento de entregas em tempo real. Este projeto está sendo construído como uma ferramenta de aprendizado robusta, mas com arquitetura e funcionalidades pensadas para um produto comercial viável.

---

## 📖 Tabela de Conteúdos

* [Sobre o Projeto](#-sobre-o-projeto)
    * [Principais Funcionalidades](#-principais-funcionalidades)
    * [Tecnologias Utilizadas (Tech Stack)](#-tecnologias-utilizadas-tech-stack)
* [🚀 Começando](#-começando)
    * [Pré-requisitos](#-pré-requisitos)
    * [Instalação](#-instalação)
* [💾 Banco de Dados](#-banco-de-dados)
* [🤝 Contribuição](#-contribuição)
* [📝 Licença](#-licença)

---

## 🌟 Sobre o Projeto

O **BeDeli** é uma solução de software projetada para gerenciar a logística de entregas gerais (como gás, água, lanches, etc.) com foco no acompanhamento em tempo real.

O sistema é dividido em três interfaces principais:
1.  **📱 App do Cliente:** Permite ao cliente visualizar produtos, fazer pedidos e acompanhar a localização exata do entregador no mapa.
2.  **📱 App do Entregador:** Permite ao entregador gerenciar seu estoque no veículo, receber novas ordens de entrega e seguir uma rota otimizada que se atualiza dinamicamente conforme novos pedidos são atribuídos.
3.  **🖥️ Dashboard da Loja:** Uma "torre de controle" que permite à loja monitorar a localização de todos os entregadores em tempo real, gerenciar pedidos, produtos e verificar o faturamento.

### ✨ Principais Funcionalidades

* Rastreamento GPS em tempo real do entregador.
* Roteamento dinâmico para otimização de entregas.
* Gerenciamento de estoque móvel (o que o entregador tem no veículo).
* Comunicação instantânea entre as três interfaces usando WebSockets.
* Arquitetura escalável pronta para produção.

### 🛠️ Tecnologias Utilizadas (Tech Stack)

Este projeto utiliza um conjunto de tecnologias modernas para garantir performance e escalabilidade.

* **Backend:** Node.js com Express
* **Comunicação em Tempo Real:** Socket.IO
* **Banco de Dados:** PostgreSQL
* **Extensão Geoespacial:** PostGIS (para cálculos de rota e distância)
* **Apps Móveis (Cliente/Entregador):** React Native com Expo
* **APIs de Mapa:** Google Maps Platform / Mapbox

---

## 🚀 Começando

Siga estas instruções para obter uma cópia funcional do projeto em sua máquina local para desenvolvimento e testes.

### ✅ Pré-requisitos

Para rodar este projeto, você precisará ter as seguintes ferramentas instaladas:

* [Git](https://git-scm.com/)
* [Node.js](https://nodejs.org/) (versão 18 ou superior)
* [PostgreSQL](https://www.postgresql.org/download/) (versão 15 ou superior)
* [PostGIS](https://postgis.net/install/) (extensão para o PostgreSQL)

### 📦 Instalação

1.  **Clone o repositório:**
    ```bash
    git clone [https://github.com/JoaoVieiraZP/BeDeli.git](https://github.com/JoaoVieiraZP/BeDeli.git)
    cd BeDeli
    ```

2.  **Instale as dependências do Backend:**
    ```bash
    # (Ainda a ser implementado - por enquanto, só temos o banco)
    # npm install
    ```

3.  **Configure o Banco de Dados:**
    Veja a seção [Banco de Dados](#-banco-de-dados) abaixo para restaurar a estrutura e os dados.

---

## 💾 Banco de Dados

O estado atual do banco de dados (estrutura e dados de teste) está salvo no arquivo `BeDeliBackup.sql`.

Para restaurar o banco em sua máquina:

1.  **Crie um novo banco de dados** no PostgreSQL (ex: pelo DBeaver ou `psql`):
    ```sql
    CREATE DATABASE "BeDeli";
    ```
2.  **Ative a extensão PostGIS** neste novo banco (necessário antes de importar):
    ```sql
    -- Conecte-se ao banco BeDeli e rode:
    CREATE EXTENSION IF NOT EXISTS postgis;
    ```
3.  **Restaure o backup** usando a ferramenta `psql`. Abra seu terminal (`cmd`) e execute:
    ```bash
    psql -U seu-usuario-postgres -d BeDeli -f BeDeliBackup.sql
    ```
    (Ele pedirá sua senha do PostgreSQL).

Alternativamente, você pode abrir o arquivo `BeDeliBackup.sql` em um editor de SQL (como o DBeaver), conectar-se ao banco `BeDeli` e executar o script inteiro.

---

## 🤝 Contribuição

Este é um projeto de aprendizado, mas contribuições são bem-vindas! Se você tiver sugestões para melhorar o código ou a arquitetura, sinta-se à vontade para abrir uma *Issue* ou enviar um *Pull Request*.

---