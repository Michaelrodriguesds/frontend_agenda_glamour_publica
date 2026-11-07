# Estilos do app + cor da marca — como funciona (BelaAgenda)

## O que o usuário vê

No **Início**, o botão 🎨 abre os estilos: **Rosé** (o original), **Lavanda**,
**Oceano**, **Esmeralda**, **Champanhe** e **Claro** (fundo branco).

Logo acima tem a chave **"Usar a cor da minha marca"** (ligada por padrão):

- **Ligada:** fundo, cartões e textos vêm do estilo; **botões e destaques** usam a cor
  que o negócio escolheu no cadastro (Configurações do negócio).
- **Desligada:** tudo vem do estilo.

A escolha do estilo e da chave fica salva **no aparelho**. A cor da marca é do
**negócio** (salva no servidor), então é a mesma em todos os aparelhos.

Depois de trocar, o app volta para o Início (explicado abaixo).

## A ideia em 5 peças

```
app_palette.dart    → "cardápio" de estilos (cada estilo = um conjunto de cores)
brand_color.dart    → ajusta a cor da marca para ter leitura no estilo
app_colors.dart     → AppColors.rose, AppColors.card... devolvem a cor ATIVA
theme_provider.dart → guarda estilo + chave da marca no aparelho
main.dart           → junta estilo + marca do negócio e redesenha o app
```

### Cor da marca que não dá leitura
Cada negócio escolhe a cor que quiser, e algumas não funcionam em todo estilo
(amarelo-claro em fundo branco some; azul-marinho em fundo escuro some; o texto
dos botões é branco). `BrandColor.fit` mantém o **tom** e só clareia ou escurece
o mínimo para passar em duas regras de acessibilidade (contraste ≥ 3):
1. texto branco por cima da cor (botões);
2. a cor por cima do cartão do estilo (ícones e títulos).

Se a cor já passa, ela fica **exatamente** como foi escolhida (ex.: o lilás padrão
#B47FD4 no Rosé). Conferido para as 6 cores do cadastro e 7 cores "difíceis" em
todos os estilos (`test/theme_test.dart`).

Se a marca for parecida com a cor secundária do estilo (marca lilás no Rosé), a
secundária vira a principal do estilo, para as duas não se confundirem.

### Cores dos serviços
Os serviços são livres em cada negócio, então a cor vai pela **posição** na lista
(1º serviço = 1ª cor…). No Rosé as cores são as mesmas de antes.

### Por que tantos `const` sumiram
`const` é calculado quando o app é compilado e nunca muda. A cor agora depende do
estilo e do negócio, então só existe com o app rodando. Os `const` que prendiam cor
foram removidos com um analisador de código (tree-sitter), e os avisos
`prefer_const_*` foram desligados em `analysis_options.yaml`.

### Redesenhar o app
O `MaterialApp` recebe `key: ValueKey('<estilo>|<cor principal>')`. Mudou o estilo,
a chave ou a cor do negócio → o Flutter monta o app de novo e toda tela relê as
cores. Login, configuração e cache ficam nos providers (fora do MaterialApp) e não se perdem.

## Criar um estilo novo
1. Em `app_palette.dart`, copie um estilo, mude `id` (único), `name`, `description` e as cores.
2. Coloque na lista `AppPalette.all`.
3. Rode `flutter test`: `test/theme_test.dart` confere a leitura.
