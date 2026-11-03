from contextlib import asynccontextmanager
import json
import os
from pathlib import Path

from fastapi import FastAPI
from pydantic import BaseModel, Field

from .engine import SearchEngine
from .corrections import apply_corrections


class SearchRequest(BaseModel):
    query: str = Field(min_length=1, max_length=160)
    category: int = Field(default=0, ge=0, le=4)
    limit: int = Field(default=6, ge=1, le=8)


def create_app(engine=None):
    @asynccontextmanager
    async def lifespan(app):
        if app.state.engine is None:
            from sentence_transformers import SentenceTransformer
            catalog = Path(os.getenv('CATALOG_PATH', '/app/assets/cantos.json'))
            songs = json.loads(catalog.read_text(encoding='utf-8'))
            metadata = catalog.with_name('portal_metadata.json')
            if metadata.exists():
                overrides = json.loads(metadata.read_text(encoding='utf-8')).get('categoryOverrides', {})
                for song in songs:
                    song['categoria'] = overrides.get(song['html'], song.get('categoria', 0))
            reviewed = catalog.with_name('reviewed_html_corrections.json')
            if reviewed.exists():
                apply_corrections(songs, json.loads(reviewed.read_text(encoding='utf-8'))['songs'])
            model = SentenceTransformer(os.getenv('EMBEDDING_MODEL', 'sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2'),
                                        revision=os.getenv('MODEL_REVISION', 'main'), device='cpu', trust_remote_code=False)
            model.max_seq_length = 128
            app.state.engine = SearchEngine(songs, model,
                                            semantic_threshold=float(os.getenv('SEMANTIC_THRESHOLD', '0.55')))
        yield

    app = FastAPI(title='Ressuscitou Search', lifespan=lifespan)
    app.state.engine = engine

    @app.get('/healthz')
    def health():
        return {'ready': app.state.engine is not None}

    @app.post('/search')
    def search(request: SearchRequest):
        return {'results': app.state.engine.search(request.query.strip(), request.category, request.limit)}

    return app


app = create_app()
