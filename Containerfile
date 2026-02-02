FROM node:24-slim

# Install dependencies required for the install script
RUN apt update && apt install -y curl bash git


# Set working directory
WORKDIR /root/


RUN useradd -m njl 

USER njl
# Install amp-cli
RUN curl -fsSL https://ampcode.com/install.sh | bash

WORKDIR /home/njl/ 

# Default command
CMD ["bash","-c",".amp/bin/amp"]
