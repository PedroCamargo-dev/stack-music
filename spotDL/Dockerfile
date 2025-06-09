# Usando Python como base
FROM python:3.11-slim

# Instala dependências
RUN apt-get update && apt-get install -y ffmpeg git && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Instala o spotDL
RUN pip install --no-cache-dir spotdl

# Cria diretório de downloads
WORKDIR /music
VOLUME ["/music"]

# Mantém o container rodando
CMD ["tail", "-f", "/dev/null"]