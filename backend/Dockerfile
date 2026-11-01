FROM python:3.11-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 HF_HOME=/opt/models OMP_NUM_THREADS=2 HF_HUB_DISABLE_XET=1
WORKDIR /app
COPY backend/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cpu 'torch>=2.7,<3' \
 && pip install --no-cache-dir -r requirements.txt
ARG PREFETCH_MODEL=1
RUN if [ "$PREFETCH_MODEL" = 1 ]; then python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2', device='cpu', trust_remote_code=False)"; fi
COPY backend/search_service ./search_service
COPY assets/cantos.json assets/portal_metadata.json ./assets/
RUN useradd --uid 10001 --create-home appuser && chown -R appuser /app /opt/models
USER appuser
EXPOSE 8080
HEALTHCHECK --start-period=600s --interval=30s CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/healthz', timeout=5)" || exit 1
CMD ["uvicorn", "search_service.app:app", "--host", "0.0.0.0", "--port", "8080", "--workers", "1", "--limit-concurrency", "16"]
