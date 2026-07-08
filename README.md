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

Informe a chave da API com `--dart-define` ao rodar o app:

```powershell
flutter run -d chrome --web-port 5174 --dart-define=GEMINI_API_KEY=SUA_CHAVE_AQUI
```

O modelo padrão usado para extração é `gemini-2.5-flash-lite`, escolhido por ser leve, econômico e adequado para tarefas simples de extração/classificação. Para trocar o modelo sem mexer no código:

```powershell
flutter run -d chrome --web-port 5174 --dart-define=GEMINI_API_KEY=SUA_CHAVE_AQUI --dart-define=GEMINI_MODEL=gemini-3.5-flash
```

Não coloque a chave diretamente no código nem faça commit dela no repositório.

## Observações

Os dados são salvos localmente pelo Hive. Na Web, é recomendado usar sempre a mesma porta, como `5174`, para manter o mesmo armazenamento local do navegador entre execuções.

Caso queira limpar os dados salvos, limpe os dados do site no navegador ou rode o app em outro perfil/navegador.
