FROM python:3.13-slim-bookworm

LABEL maintainer="VoteChain Team" \
      service="biometric-service" \
      version="0.1.0"

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN adduser --disabled-password --no-create-home votechain && \
    chown -R votechain:votechain /app
USER votechain

EXPOSE 8001

HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8001/health')" || exit 1

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001"]
