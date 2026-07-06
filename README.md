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

## Próximas melhorias planejadas

Uma das próximas funcionalidades será o reconhecimento de uma lista física de compras usando a câmera do celular.

A proposta é permitir que o usuário tire uma foto de uma lista escrita em papel e o aplicativo utilize uma API de inteligência artificial da Google para reconhecer os itens automaticamente. Depois disso, os itens poderão ser adicionados à lista digital e organizados por seção.

Essa funcionalidade ainda será integrada ao fluxo principal do app.

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

## Observações

Os dados são salvos localmente pelo Hive. Na Web, é recomendado usar sempre a mesma porta, como `5174`, para manter o mesmo armazenamento local do navegador entre execuções.

Caso queira limpar os dados salvos, limpe os dados do site no navegador ou rode o app em outro perfil/navegador.
