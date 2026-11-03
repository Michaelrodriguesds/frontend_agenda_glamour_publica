# BelaAgenda — App Flutter

Agenda online para negócios de beleza. Cada usuário configura logo, cor, serviços e 1–2 locais.
Teste grátis de 30 dias; depois o app mostra a tela de bloqueio com o **ID** do cliente e um botão de WhatsApp para você liberar.

## Rodar em desenvolvimento
```bash
flutter pub get
flutter run --dart-define=API_URL=http://10.0.2.2:5000     # emulador Android → backend local
```

## Gerar o app para a Play Store
1. Crie a chave de assinatura (uma vez, GUARDE o arquivo e as senhas):
   ```bash
   keytool -genkey -v -keystore ~/belaagenda-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Crie `android/key.properties` (já está no .gitignore):
   ```
   storePassword=SUA_SENHA
   keyPassword=SUA_SENHA
   keyAlias=upload
   storeFile=/caminho/completo/belaagenda-upload.jks
   ```
3. Gere o pacote:
   ```bash
   flutter build appbundle --release \
     --dart-define=API_URL=https://SEU-SERVICO.onrender.com \
     --dart-define=SUPPORT_WHATSAPP=5521999999999
   ```
   Arquivo: `build/app/outputs/bundle/release/app-release.aab`

## Identidade
- applicationId: `com.belaagenda.app` (troque em `android/app/build.gradle.kts` + pasta `kotlin/` se quiser outro; não dá para mudar depois de publicado)
- Ícone: já gerado (flor). Troque os `mipmap-*/ic_launcher.png` se quiser outro.
- O app é só Android (pastas iOS/desktop/web removidas).
