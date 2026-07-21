# MercadoSmart

MercadoSmart é um aplicativo Flutter para organizar listas de compras por mercado e por seções do supermercado. A ideia principal é reduzir a quantidade de toques durante a compra e deixar o percurso mais prático: o usuário cria uma lista, adiciona itens rapidamente, acompanha os produtos por seção e marca o que já foi comprado.

O projeto está sendo desenvolvido para a disciplina de dispositivos móveis, com foco em uma experiência simples, moderna e útil no dia a dia.

## O que o app já possui

- Criação de listas de compras.
- Cadastro e reutilização de mercados.
- Cadastro rápido de itens com nome, quantidade, preço e seção.
- Organização dos itens por seções do supermercado.
- Criação, edição, remoção e reordenação de seções.
- Tela de compra com checkbox para marcar itens comprados.
- Persistência local com Hive.
- Cálculo automático do total previsto da compra.
- Cálculo do total já comprado em tempo real.
- Histórico de compras por mercado.
- Reutilização de compras anteriores como uma nova lista.
- Interface em Material 3, com cards, dialogs, bottom sheets e barra inferior de totais.

## Importação por foto com IA

O app já possui fluxo de importação por foto:

- o usuário tira uma foto ou escolhe uma imagem da galeria;
- o Google ML Kit extrai o texto da imagem via OCR em Android/iOS;
- o texto é enviado para um interpretador de lista;
- os itens reconhecidos aparecem em uma tela de revisão antes de entrar na lista.

Quando a chave do Gemini é informada, o app usa a Gemini API para extrair os produtos, quantidades e seções. Sem chave, ele usa um classificador local por palavras-chave, mantendo o app funcional para testes e apresentação.

## Como rodar o projeto

Antes de rodar, instale o Flutter e abra o projeto no VS Code ou em outro editor de sua preferência.

Na raiz do projeto, execute:

```powershell
flutter pub get
```

Para rodar pela Web no Chrome:

```powershell
flutter run -d chrome --web-port 5174
```

Se preferir rodar como servidor local e abrir manualmente no navegador:

```powershell
flutter run -d web-server --web-port 5174
```

Depois abra a URL exibida no terminal.

### Rodando com Gemini

Para Android/iOS ou testes locais fora da Web publica, informe a chave da API com `--dart-define` ao rodar o app:

```powershell
flutter run --dart-define=GEMINI_API_KEY=SUA_CHAVE_AQUI
```

O modelo padrão usado para extração é `gemini-2.5-flash-lite`, escolhido por ser leve, econômico e adequado para tarefas simples de extração/classificação. Para trocar o modelo sem mexer no código:

```powershell
flutter run --dart-define=GEMINI_API_KEY=SUA_CHAVE_AQUI --dart-define=GEMINI_MODEL=gemini-3.5-flash
```

Não coloque a chave diretamente no código nem faça commit dela no repositório.

### Gemini seguro na Web com Vercel

Para producao Web, nao envie `GEMINI_API_KEY` com `--dart-define`, porque valores enviados para o Flutter Web podem aparecer no JavaScript final.

O projeto inclui funcoes serverless para texto e imagem:

- `api/interpret-shopping-list.js`: interpreta listas digitadas ou texto ja extraido.
- `api/interpret-shopping-image.js`: recebe a foto pela Web e usa Gemini multimodal para extrair o texto e os itens diretamente da imagem.

No deploy da Vercel, configure a variavel de ambiente:

```text
GEMINI_API_KEY=SUA_CHAVE_AQUI
```

Opcionalmente, configure o modelo:

```text
GEMINI_MODEL=gemini-2.5-flash-lite
```

Na Web, o app chama `/api/interpret-shopping-list` para texto e `/api/interpret-shopping-image` para fotos. As funcoes chamam a Gemini API pelo servidor, mantendo a chave protegida no ambiente da Vercel. Em Android/iOS, o app continua usando o Google ML Kit para OCR local antes de interpretar os itens.

As imagens escolhidas pelo app sao comprimidas antes do envio para evitar o limite de payload das Vercel Functions.

Arquivos de deploy:

- `vercel.json`: aponta o build para `flutter build web` e publica `build/web`.
- `vercel-build.sh`: instala Flutter stable no ambiente da Vercel quando necessario.
- `.env.example`: lista as variaveis esperadas sem incluir segredo real.

## Observações

Os dados são salvos localmente pelo Hive. Na Web, é recomendado usar sempre a mesma porta, como `5174`, para manter o mesmo armazenamento local do navegador entre execuções.

Caso queira limpar os dados salvos, limpe os dados do site no navegador ou rode o app em outro perfil/navegador.
