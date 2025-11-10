# 📱 Instruções para Gerar APK de Produção

Seu app **PDF fácil** está pronto para ser distribuído! Siga os passos abaixo para gerar um APK profissional.

## 🔑 Passo 1: Criar uma Keystore (Certificado de Assinatura)

Execute este comando **uma única vez** para criar seu certificado:

```bash
keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias flutter_key
```

**Responda as perguntas:**
- **Senha da keystore**: Digite uma senha segura (anote-a!)
- **Nome**: Seu nome completo
- **Organização**: Seu nome ou empresa
- **Cidade**: Sua cidade
- **Estado**: Seu estado
- **País**: BR (para Brasil)

Ou no **Windows PowerShell**, use:

```powershell
keytool -genkey -v -keystore "$env:USERPROFILE\key.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias flutter_key
```

> ⚠️ **IMPORTANTE**: Guarde este arquivo `key.jks` em um lugar seguro. Você vai precisar dele para futuras atualizações!

---

## 🔐 Passo 2: Criar arquivo de configuração de assinatura

Crie um arquivo chamado `android/key.properties` com este conteúdo:

```properties
storePassword=SUA_SENHA_AQUI
keyPassword=SUA_SENHA_AQUI
keyAlias=flutter_key
storeFile=../key.jks
```

Substitua `SUA_SENHA_AQUI` pela senha que você criou no Passo 1.

---

## 📦 Passo 3: Configurar a assinatura no Gradle

Abra `android/app/build.gradle.kts` e adicione isto **antes de `android {`**:

```kotlin
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

E adicione isto **dentro de `android {`** após `kotlinOptions { ... }`:

```kotlin
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}
```

---

## ✅ Passo 4: Gerar o APK

Use este comando no terminal (na pasta raiz do projeto):

```bash
flutter build apk --release
```

Ou no **Windows PowerShell**:

```powershell
flutter build apk --release
```

O APK será criado em:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 🚀 Passo 5: Compartilhar via WhatsApp

1. Abra o WhatsApp
2. Envie o arquivo `app-release.apk` para o seu contato
3. O usuário pode instalar clicando no arquivo

> 💡 **Dica**: Envie também as instruções de instalação para o usuário.

---

## 📋 Instruções para o Usuário Instalar

Compartilhe isto com quem vai instalar:

```
📱 Como instalar o PDF fácil:

1. Baixe o arquivo "app-release.apk"
2. Abra o gerenciador de arquivos
3. Localize o arquivo baixado
4. Clique para instalar
5. Clique em "Instalar" quando solicitado
6. Pronto! O app está instalado!

⚠️ Se aparecer mensagem de "Origem desconhecida":
- Vá em Configurações > Segurança
- Habilite "Instalar de fontes desconhecidas"
- Tente instalar novamente
```

---

## 🔄 Para Atualizar o App Posteriormente

1. Aumente o número de versão em `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2  # Aumentar o número após o +
   ```

2. Repita o **Passo 4** para gerar um novo APK

3. Compartilhe o novo APK com os usuários

---

## ❓ Dúvidas Frequentes

**P: Por quanto tempo o app funciona?**
R: Para sempre! Não há limite de tempo. O certificado é válido por 10 anos.

**P: Posso compartilhar o arquivo APK via WhatsApp?**
R: Sim! O arquivo é apenas para compartilhamento. Os usuários podem instalar sem problemas.

**P: E se eu perder o arquivo key.jks?**
R: Você não conseguirá atualizar o app na PlayStore (se houver). Por isso, guarde bem!

---

✨ **Seu app está pronto para produção!**
