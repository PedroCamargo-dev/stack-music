# Usando uma imagem base leve do Python
FROM python:3.11-slim

# Atualizando e instalando dependências necessárias
RUN apt-get update && \
    apt-get install -y ffmpeg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Instalando o yt-dlp diretamente do repositório oficial
RUN pip install --no-cache-dir yt-dlp

# Criando o diretório para downloads
RUN mkdir /downloads

# Definindo o diretório de trabalho
WORKDIR /downloads

# Definindo o comando padrão para manter o container ativo
CMD ["tail", "-f", "/dev/null"]
