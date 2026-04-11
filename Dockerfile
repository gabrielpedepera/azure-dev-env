FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Mirror cloud-init packages
RUN apt-get update && apt-get install -y \
    git curl zsh unzip xz-utils fontconfig \
    build-essential python3-pip docker.io sudo \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js (mirrors runcmd)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Create user (mirrors VM adminUsername)
RUN useradd -m -s /bin/zsh gabrielpedepera \
    && echo "gabrielpedepera ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && usermod -aG docker gabrielpedepera

USER gabrielpedepera
WORKDIR /home/gabrielpedepera

# Install chezmoi (mirrors runcmd)
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
ENV PATH="/home/gabrielpedepera/.local/bin:${PATH}"

# Pre-configure chezmoi data (mirrors runcmd)
RUN mkdir -p "$HOME/.config/chezmoi" \
    && printf '[data]\n    name = "Gabriel Pereira"\n    email = "gabrielpedepera@gmail.com"\n' \
    > "$HOME/.config/chezmoi/chezmoi.toml"

# Apply dotfiles (mirrors runcmd)
RUN chezmoi init --apply gabrielpedepera/dotfiles

# Smoke tests: verify all expected tools
ENV PATH="/home/gabrielpedepera/.local/bin:/home/gabrielpedepera/.atuin/bin:${PATH}"
RUN echo "=== Smoke Tests ===" \
    && command -v chezmoi && echo "✓ chezmoi" \
    && command -v nvim && echo "✓ nvim" \
    && command -v fzf && echo "✓ fzf" \
    && command -v duf && echo "✓ duf" \
    && command -v tldr && echo "✓ tldr" \
    && command -v zsh && echo "✓ zsh" \
    && command -v oh-my-posh && echo "✓ oh-my-posh" \
    && command -v atuin && echo "✓ atuin" \
    && command -v copilot && echo "✓ copilot" \
    && command -v docker && echo "✓ docker" \
    && command -v delta && echo "✓ delta" \
    && command -v node && echo "✓ node" \
    && nvim --headless -c 'echo "nvim ok"' -c 'q' 2>&1 \
    && echo "=== All smoke tests passed! ==="
