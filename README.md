# Cadastro de Feiticeiros — Flutter + Firebase

Projeto da atividade com login Google, Central Jujutsu e gerenciamento das missões do usuário autenticado.

## Funcionalidades

- Login com Google usando Firebase Authentication.
- Exibição da foto, nome e e-mail da pessoa autenticada.
- Cadastro de missão com `titulo`, `grau`, `concluida: false` e `usuarioId`.
- Listagem em tempo real somente das missões do usuário logado.
- Marcar missão como concluída e excluir missão.
- Sair da conta.
- Regras do Firestore incluídas no arquivo `firestore.rules`.

## Configuração obrigatória do Firebase

O arquivo `lib/firebase_options.dart` não está incluído porque ele é gerado para o projeto Firebase da sua conta. Siga as etapas abaixo.

### 1. Criar ou escolher um projeto Firebase

1. Acesse https://console.firebase.google.com/ e crie um projeto chamado `Cadastro de Feiticeiros`.
2. Você também pode usar outro projeto Firebase, mas selecione o mesmo projeto nas etapas seguintes.

### 2. Ativar login com Google

1. No console do Firebase, abra **Authentication**.
2. Clique em **Começar**, se necessário.
3. Entre na aba **Método de login** / **Sign-in method**.
4. Selecione **Google** e ative o provedor.
5. Escolha um e-mail de suporte e salve.
6. Em Authentication > Settings > Authorized domains, confira se `localhost` está autorizado para os testes locais.

### 3. Criar o Cloud Firestore

1. Abra **Firestore Database**.
2. Clique em **Criar banco de dados**.
3. Crie o banco e escolha uma região adequada, por exemplo `southamerica-east1` se estiver disponível.
4. Depois que o banco estiver criado, abra a aba **Regras**.
5. Copie o conteúdo de `firestore.rules` deste projeto e publique as regras.

As regras garantem que uma pessoa autenticada só possa ler, criar, alterar ou excluir missões com o próprio `usuarioId`. Não deixe regras abertas em produção.

### 4. Conectar este app ao Firebase

Abra no VS Code a pasta que contém este `pubspec.yaml`. No terminal integrado, execute um comando por vez:

```powershell
flutter pub get
```

Se as ferramentas ainda não estiverem instaladas, instale e entre no Firebase:

```powershell
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
```

Se `flutterfire` não for reconhecido no PowerShell, execute:

```powershell
$env:Path += ";$env:LOCALAPPDATA\Pub\Cache\bin"
```

Agora conecte o app:

```powershell
flutterfire configure
```

Selecione o projeto criado para esta atividade e marque **somente Web** se for executar pelo Chrome. Ao concluir, o comando criará `lib/firebase_options.dart`.

### 5. Executar no Chrome

```powershell
flutter pub get
flutter run -d chrome
```

Clique em **ENTRAR COM GOOGLE** e escolha uma conta Google. Depois, cadastre uma missão. No Console do Firebase, abra Firestore Database > Dados e confira a coleção `missoes`.

## Como conferir a regra de privacidade

Cadastre uma missão com a primeira conta Google. Saia e entre com uma segunda conta. A missão da primeira conta não deve aparecer para a segunda. Cada documento terá estes campos:

- `titulo`: título da missão
- `grau`: grau numérico (1 a 4) ou `Especial`
- `concluida`: `false` inicialmente e `true` quando marcada
- `usuarioId`: UID da conta Google autenticada

## Observações

- O projeto está preparado para executar primeiro no navegador Chrome (Web), conforme o fluxo de configuração acima.
- O app depende da configuração Firebase da sua conta; por isso, é necessário gerar `firebase_options.dart` antes da primeira execução.
- Se o Firebase apresentar `permission-denied`, confira se publicou as regras de `firestore.rules` e se o usuário está autenticado.
