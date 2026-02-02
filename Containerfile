FROM node:24-slim

# Install dependencies required for the install script
RUN apt-get update && apt-get install -y curl bash git && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /root/

RUN useradd -m ampy

USER ampy
# Install amp-cli
RUN curl -fsSL https://ampcode.com/install.sh | bash

WORKDIR /home/ampy/

# Default command
CMD ["bash","-c",".amp/bin/amp"]