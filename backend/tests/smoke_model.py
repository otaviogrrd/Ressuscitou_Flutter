"""Network-enabled CI verification with real multilingual embeddings and catalog."""
import json
import os

from sentence_transformers import SentenceTransformer

from search_service.engine import SearchEngine

model = SentenceTransformer('sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2', device='cpu', trust_remote_code=False)
model.max_seq_length = 128
songs = json.load(open('assets/cantos.json', encoding='utf-8'))
if isinstance(songs, dict):
    songs = songs['cantos']
engine = SearchEngine(songs, model)
assert engine.documents
results = engine.search('levando sempre o poder de Jesus')
assert results, 'Real catalog/model retrieval returned no results'
assert all(result['html'] in {song['html'] for song in songs} for result in results)
pairs = model.encode(['Estou chorando de tristeza.', 'As lágrimas caem dos meus olhos.',
                      'A bicicleta está na oficina.'], normalize_embeddings=True)
assert float(pairs[0] @ pairs[1]) > float(pairs[0] @ pairs[2]), 'Portuguese paraphrase ranking failed'
print(json.dumps({'modelLoaded': True, 'chunks': len(engine.documents), 'results': len(results)}))
