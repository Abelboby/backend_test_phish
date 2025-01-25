FROM python:3.9-slim

WORKDIR /app

# Install system dependencies and build tools for PyAudio
RUN apt-get update && apt-get install -y \
    gcc \
    libasound2-dev \
    portaudio19-dev \
    python3-pyaudio \
    python3-dev \
    libportaudio2 \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install portaudio development files
RUN apt-get update && apt-get install -y \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Create directories for models
RUN mkdir -p /vosk/model && \
    mkdir -p /app/phishing_detection_model

# Download and setup Vosk model (using smaller model)
RUN cd /vosk && \
    wget https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip && \
    apt-get update && apt-get install -y unzip && \
    unzip vosk-model-small-en-us-0.15.zip && \
    mv vosk-model-small-en-us-0.15/* model/ && \
    rm -rf vosk-model-small-en-us-0.15.zip vosk-model-small-en-us-0.15 && \
    apt-get remove -y unzip && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
COPY phishing_detection_model /app/phishing_detection_model

# Set environment variables for memory optimization
ENV PYTORCH_NO_CUDA=1
ENV TRANSFORMERS_CACHE=/tmp/transformers_cache
ENV PYTORCH_CPU_ONLY=1
ENV PYTHONUNBUFFERED=1
ENV MALLOC_TRIM_THRESHOLD_=100000
ENV PYTORCH_MPS_ENABLE_IF_AVAILABLE=0
ENV OMP_NUM_THREADS=1
ENV PYTHONOPTIMIZE=2

# Clean install of dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir numpy==1.24.3 && \
    pip install --no-cache-dir -r requirements.txt && \
    rm -rf /root/.cache/pip

COPY ./app .

EXPOSE 5000

# Run with memory optimization flags
CMD ["python", "-X", "utf8", "main.py"] 