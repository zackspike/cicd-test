# 1. Imagen base oficial ligera de Python 3.11
FROM python:3.11-slim

# 2. Establecer el directorio de trabajo dentro del contenedor
WORKDIR /app

# 3. Copiar e instalar dependencias primero
# (Buenas prácticas: aprovecha la caché de capas de Docker si los requisitos no cambian)
COPY src/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 4. Copiar el código fuente al contenedor
COPY src/ .

# 5. Comando por defecto al ejecutar el contenedor
CMD ["python", "main.py"]