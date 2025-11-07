# =========================
# Stage 1: Builder
# =========================
FROM debian:bookworm AS builder

# Install dependencies
RUN apt-get update -y && \
    apt-get install -y vim build-essential cmake git python3 python3-pip curl pkg-config zip && \
    rm -rf /var/lib/apt/lists/*

# Install emsdk (Emscripten)
RUN git clone https://github.com/emscripten-core/emsdk.git /emsdk \
 && cd /emsdk \
 && ./emsdk install latest \
 && ./emsdk activate latest

# Add Emscripten to the environment
ENV EMSDK=/emsdk
ENV PATH="/emsdk:/emsdk/upstream/emscripten:$PATH"
ENV EM_CONFIG=/emsdk/.emscripten
ENV EM_CACHE=/emsdk/.emscripten_cache

# Copy Leo-engine-game source
WORKDIR /leo-pong
COPY . .

# Build Leo-pong with Emscripten (using FetchContent)
RUN emcmake cmake -B build -S . -DCMAKE_BUILD_TYPE=Release \
 && cmake --build build --parallel

# Prepare web output
RUN mkdir -p /webdist && \
    cp build/leo-pong.html /webdist/index.html && \
    cp build/leo-pong.js /webdist/ && \
    cp build/leo-pong.wasm /webdist/ && \
    cp build/leo-pong.data /webdist/ && \
    if [ -f resources.leopack ]; then \
        cp resources.leopack /webdist/; \
    elif [ -d resources ]; then \
        cp -r resources /webdist/; \
    fi && \
    cd / && zip -r /webdist/webdist.zip webdist

# =========================
# Stage 2: Runtime
# =========================
FROM python:3.11-slim AS runtime

# Copy build artifacts from builder
COPY --from=builder /webdist /webdist

# Expose HTTP port
EXPOSE 8000

# Serve /webdist for local dev
WORKDIR /webdist
CMD ["python3", "-m", "http.server", "8000"]
