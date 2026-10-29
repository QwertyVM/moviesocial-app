FROM python:3.11-slim

WORKDIR /app

# Instalar dependencias
COPY backend/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el código del backend
COPY backend/ ./

ENV PORT=8080
EXPOSE 8080

CMD ["python", "server.py"]
