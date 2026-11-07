#!/usr/bin/env bash
set -e

# Baixa o Flutter (versao estavel) dentro do build do Netlify
if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$HOME/flutter"
fi
export PATH="$HOME/flutter/bin:$PATH"

flutter config --enable-web
flutter --version

# Cria a pasta web caso nao esteja no repositorio
if [ ! -f web/index.html ]; then
  flutter create . --platforms=web
fi

flutter pub get
flutter build web --release --dart-define=API_URL="$API_URL"