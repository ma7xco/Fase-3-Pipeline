# ==========================================
# Stage 1: Builder
# ==========================================
FROM golang:1.22-alpine AS builder

# Definir diretório de trabalho
WORKDIR /app

# Copiar todos os arquivos do projeto
COPY . .

# Baixar dependências e compilar o binário estático (CGO_ENABLED=0 é vital para o Alpine)
RUN go mod tidy && go mod download
RUN CGO_ENABLED=0 GOOS=linux go build -o server .

# ==========================================
# Stage 2: Runtime
# ==========================================
FROM alpine:latest

# Criar um usuário não-root por questões de segurança (DevSecOps)
# No Alpine, usamos addgroup e adduser
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Definir o diretório de trabalho do container final
WORKDIR /app

# Copiar apenas o binário compilado do stage 1, já passando a posse para o usuário seguro
COPY --from=builder --chown=appuser:appgroup /app/server .

# Trocar do usuário root para o usuário não privilegiado
USER appuser

# Expor a porta do evaluation-service
EXPOSE 8004

# Comando de inicialização
CMD ["./server"]