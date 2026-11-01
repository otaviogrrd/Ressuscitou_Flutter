"""Portuguese lexical + multilingual semantic retrieval over original black HTML."""
import base64
from collections import Counter
import hashlib
from html.parser import HTMLParser
import math
import re
import sqlite3
import threading
import unicodedata

import numpy as np
import snowballstemmer

STOP = set('a as o os ao aos de da das do dos e em na nas no nos um uma uns umas para por com que'.split())


def normalize(text):
    return ''.join(c for c in unicodedata.normalize('NFD', text.lower())
                   if not unicodedata.combining(c))


class BlackText(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.stack = []
        self.parts = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        black, hidden = self.stack[-1][1:] if self.stack else (False, False)
        style = attrs.get('style', '')
        hidden |= tag in {'head', 'script', 'style', 'h1'} or 'inv' in attrs.get('class', '').split()
        hidden |= 'hidden' in attrs or bool(re.search(r'display\s*:\s*none', style, re.I))
        match = re.search(r'(?:^|;)\s*color\s*:\s*([^;!]+)', style, re.I)
        color = match.group(1) if match else attrs.get('color')
        if color is not None:
            black = re.sub(r'\s', '', color.lower()) in {'#000', '#000000', 'black', 'rgb(0,0,0)', 'rgba(0,0,0,1)'}
        if color is not None or tag in {'br', 'p', 'div', 'li'}:
            self.parts.append(' ')
        if tag not in {'br', 'meta', 'img', 'hr', 'input', 'link', 'source', 'area', 'wbr'}:
            self.stack.append((tag, black, hidden))

    def handle_endtag(self, tag):
        for index in range(len(self.stack) - 1, -1, -1):
            if self.stack[index][0] == tag:
                del self.stack[index:]
                break
        self.parts.append(' ')

    def handle_data(self, text):
        if self.stack and self.stack[-1][1] and not self.stack[-1][2]:
            self.parts.append(text)


def black_lyrics(song):
    for field in ('html_base64', 'ext_base64'):
        try:
            parser = BlackText()
            parser.feed(base64.b64decode(song.get(field, ''), validate=True).decode('utf-8'))
            text = ' '.join(''.join(parser.parts).split())
            if text:
                return text
        except (ValueError, UnicodeError):
            continue
    return ''


def source_hash(song):
    value = song.get('html_base64', '') + '\n' + song.get('ext_base64', '')
    return hashlib.sha256(value.encode('utf-8')).hexdigest()


class SearchEngine:
    def __init__(self, songs, encoder, *, semantic_threshold=0.55):
        if not 0 <= semantic_threshold <= 1:
            raise ValueError('Semantic threshold must be between 0 and 1')
        self.lock = threading.Lock()
        self.encoder = encoder
        self.threshold = semantic_threshold
        self.stemmer = snowballstemmer.stemmer('portuguese')
        self.documents = []
        self.db = sqlite3.connect(':memory:', check_same_thread=False)
        self.db.execute('CREATE VIRTUAL TABLE chunks USING fts5(terms)')
        for song in songs:
            words = black_lyrics(song).split()
            for start in range(0, len(words), 28):
                snippet = ' '.join(words[start:start + 40])
                if not snippet:
                    continue
                terms = self.terms(snippet)
                document = {'html': song['html'], 'source_hash': source_hash(song),
                            'category': song.get('categoria', 0), 'snippet': snippet, 'terms': set(terms)}
                self.documents.append(document)
                self.db.execute('INSERT INTO chunks(rowid, terms) VALUES (?, ?)',
                                (len(self.documents), ' '.join(terms)))
                if start + 40 >= len(words):
                    break
        if not self.documents:
            raise ValueError('Catalog contains no searchable black HTML')
        self.vectors = np.asarray(encoder.encode([doc['snippet'] for doc in self.documents],
                                               normalize_embeddings=True, show_progress_bar=False), dtype=np.float32)
        self.cache = {}

    def terms(self, text):
        words = re.findall(r'[^\W_]+', unicodedata.normalize('NFC', text.lower()), re.UNICODE)
        return [normalize(self.stemmer.stemWord(word)) for word in words
                if normalize(word) not in STOP and len(word) > 1]

    def search(self, query, category=0, limit=6):
        # Snowball and model inference share mutable state: one bounded query at
        # a time, one server worker. No external API keys or per-query provider.
        with self.lock:
            key = (query, category, limit)
            if key in self.cache:
                return self.cache[key]
            wanted = set(self.terms(query))
            if not wanted:
                return []
            allowed = {i for i, doc in enumerate(self.documents) if not category or doc['category'] == category}
            expression = ' OR '.join('"' + term.replace('"', '""') + '"' for term in wanted)
            rows = self.db.execute('SELECT rowid FROM chunks WHERE chunks MATCH ? ORDER BY bm25(chunks)',
                                   (expression,)).fetchall()
            lexical = [row[0] - 1 for row in rows if row[0] - 1 in allowed
                       and len(wanted & self.documents[row[0] - 1]['terms']) >= math.ceil(len(wanted) * 0.67)]
            semantic = []
            if len(wanted) >= 2:
                vector = np.asarray(self.encoder.encode([query], normalize_embeddings=True,
                                                       show_progress_bar=False), dtype=np.float32)[0]
                similarities = self.vectors @ vector
                semantic = sorted((i for i in allowed if float(similarities[i]) >= self.threshold),
                                  key=lambda i: float(similarities[i]), reverse=True)[:40]
            # Reciprocal rank fusion avoids comparing incompatible BM25 and
            # cosine score scales. Exact phrase priority remains in the app.
            scores = Counter()
            for ranking, weight in ((lexical[:40], 0.5), (semantic, 0.5)):
                for rank, index in enumerate(ranking, start=1):
                    scores[index] += weight / (60 + rank)
            results, seen = [], set()
            for index in sorted(scores, key=lambda i: (-scores[i], i)):
                doc = self.documents[index]
                if doc['html'] in seen:
                    continue
                seen.add(doc['html'])
                results.append({key: doc[key] for key in ('html', 'source_hash', 'snippet')})
                if len(results) >= limit:
                    break
            if len(self.cache) >= 256:
                self.cache.pop(next(iter(self.cache)))
            self.cache[key] = results
            return results
