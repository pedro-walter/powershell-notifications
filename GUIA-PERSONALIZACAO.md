# Guia de Personalização de Popups

Este guia compara os diferentes métodos de criar popups no Windows, do mais simples ao mais customizável.

## Comparação Rápida

| Método | Facilidade | Personalização | Imagens | Cores | Botões Custom |
|--------|------------|----------------|---------|-------|---------------|
| WScript.Shell | ⭐⭐⭐⭐⭐ Muito Fácil | ❌ Limitada | ❌ Não | ❌ Não | ❌ Não |
| Windows Forms | ⭐⭐⭐⭐ Fácil | ⚠️ Moderada | ❌ Não | ⚠️ Parcial | ⚠️ Parcial |
| WPF (XAML) | ⭐⭐⭐ Média | ✅ Total | ✅ Sim | ✅ Sim | ✅ Sim |
| HTML (HTA) | ⭐⭐ Difícil | ✅ Total | ✅ Sim | ✅ Sim | ✅ Sim |

## Método 1: WScript.Shell.Popup() ⭐ Atual

**Arquivo:** `PopupLogoff.psm1`, `Solicitar-Logoff.ps1`

### ✅ Vantagens
- Extremamente simples (1 linha de código)
- Não requer dependências extras
- Funciona em qualquer Windows
- Leve e rápido
- Ideal para popups simples

### ❌ Limitações
```
O que NÃO pode fazer:
❌ Adicionar logo/imagens
❌ Mudar cores (sempre cinza/branco)
❌ Mudar fontes
❌ Customizar texto dos botões
❌ Adicionar campos de input
❌ Layout customizado
❌ Mais de 3 botões
```

### 📋 O que PODE fazer
- ✅ Escolher ícone do sistema (Erro, Aviso, Info, Pergunta)
- ✅ Escolher combinação de botões (OK, Sim/Não, OK/Cancelar, etc.)
- ✅ Definir botão padrão
- ✅ Timeout automático
- ✅ Sempre no topo (System Modal)

### 💡 Quando usar
- Confirmações simples
- Avisos rápidos
- Quando aparência padrão do Windows é suficiente

---

## Método 2: Windows Forms MessageBox ⭐⭐

Mais controle que WScript, mas ainda limitado.

### Exemplo Básico
```powershell
Add-Type -AssemblyName System.Windows.Forms

$resultado = [System.Windows.Forms.MessageBox]::Show(
    "Deseja fazer logoff?",
    "Confirmar",
    [System.Windows.Forms.MessageBoxButtons]::YesNo,
    [System.Windows.Forms.MessageBoxIcon]::Question,
    [System.Windows.Forms.MessageBoxDefaultButton]::Button2
)

if ($resultado -eq 'Yes') {
    shutdown /l /f
}
```

### ✅ Vantagens sobre WScript
- Mais opções de ícones
- Melhor controle de botões
- Pode definir botão padrão mais facilmente

### ❌ Ainda limitado
- Sem customização de cores
- Sem imagens customizadas
- Sem layout customizado

---

## Método 3: WPF (XAML) ⭐⭐⭐ RECOMENDADO para customização

**Arquivos:**
- **PopupPersonalizado.psm1** - Módulo com função `Show-PopupPersonalizado`
- **Exibir-PopupPersonalizado.ps1** - Script de linha de comando
- **popup-personalizado-wpf.ps1** - Versão standalone (legado)

### ✅ Personalização TOTAL

**O que você PODE fazer:**
- ✅ Adicionar logos/imagens (PNG, JPG, ICO)
- ✅ Customizar cores de fundo, texto, botões
- ✅ Escolher fontes, tamanhos, estilos
- ✅ Criar layouts customizados
- ✅ Adicionar gradientes, sombras, efeitos
- ✅ Botões customizados com qualquer texto
- ✅ Adicionar checkboxes, inputs, links
- ✅ Animações
- ✅ Qualquer coisa que imaginar!

### 🎨 Exemplo Visual

O arquivo `popup-personalizado-wpf.ps1` inclui:

```
┌─────────────────────────────────────────────┐
│ 🔒  Acesso Administrativo          [X]      │  ← Header azul
├─────────────────────────────────────────────┤
│                                             │
│  Seu acesso foi concedido com sucesso!     │  ← Texto principal
│                                             │
│  É necessário fazer logoff para aplicar... │  ← Subtexto
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │ ⚠  Todos os aplicativos abertos... │   │  ← Caixa de aviso
│  └─────────────────────────────────────┘   │
│                                             │
├─────────────────────────────────────────────┤
│              [Agora Não]  [Fazer Logoff]   │  ← Botões customizados
└─────────────────────────────────────────────┘
```

### 📝 Como Personalizar

#### Mudar Cores
```xml
<!-- No XAML, procure por: -->
<Border Background="#2196F3">  <!-- Header azul -->
<Button Background="#4CAF50">  <!-- Botão verde -->
<Grid Background="#F5F5F5">    <!-- Fundo cinza claro -->
```

Cores sugeridas:
- `#2196F3` - Azul Material
- `#4CAF50` - Verde sucesso
- `#F44336` - Vermelho erro
- `#FF9800` - Laranja aviso
- `#9C27B0` - Roxo

#### Adicionar Logo/Imagem
```xml
<!-- Substituir o emoji por imagem -->
<Image Grid.Column="0"
       Source="C:\caminho\para\logo.png"
       Width="50" Height="50"
       Margin="0,0,15,0"/>
```

#### Mudar Ícones (Emojis Unicode)
```xml
<TextBlock Text="&#x1F512;"/>  <!-- 🔒 Cadeado -->
<TextBlock Text="&#x2705;"/>   <!-- ✅ Check -->
<TextBlock Text="&#x26A0;"/>   <!-- ⚠️ Aviso -->
<TextBlock Text="&#x274C;"/>   <!-- ❌ Erro -->
<TextBlock Text="&#x1F4A1;"/>  <!-- 💡 Ideia -->
```

#### Mudar Texto dos Botões
```xml
<Button Content="Sim, fazer logoff agora"/>
<Button Content="Nao, deixar para depois"/>
<Button Content="Cancelar operacao"/>
```

#### Ajustar Tamanho
```xml
<Window Height="300" Width="500">  <!-- Mudar aqui -->
```

### 💻 Como Usar

#### Método 1: Usando o Script (Recomendado)

```powershell
# Uso básico com cores padrão (azul e verde)
.\Exibir-PopupPersonalizado.ps1

# Personalizar cores
.\Exibir-PopupPersonalizado.ps1 -CorHeader "#FF9800" -CorBotaoSim "#F44336"

# Personalizar textos
.\Exibir-PopupPersonalizado.ps1 `
    -Titulo "Manutencao do Sistema" `
    -Mensagem "Atualizacao instalada!" `
    -Subtexto "Reiniciar sessao agora?" `
    -TextoBotaoSim "Sim, fazer logoff" `
    -TextoBotaoNao "Nao, deixar para depois"

# Apenas exibir popup sem executar logoff
.\Exibir-PopupPersonalizado.ps1 -NaoExecutarLogoff

# Com icone diferente (check verde)
.\Exibir-PopupPersonalizado.ps1 -IconeHeader "&#x2705;"
```

#### Método 2: Importando o Módulo

```powershell
# Importar o módulo
Import-Module ".\PopupPersonalizado.psm1"

# Usar a função
$confirmou = Show-PopupPersonalizado -Titulo "Teste" -CorHeader "#9C27B0"

if ($confirmou) {
    Write-Host "Usuario confirmou!"
}

# Sem executar logoff automaticamente
$resultado = Show-PopupPersonalizado -ExecutarLogoff $false
```

### 🎨 Exemplos Rápidos de Cores

```powershell
# Tema Azul (padrão)
.\Exibir-PopupPersonalizado.ps1 -CorHeader "#2196F3" -CorBotaoSim "#4CAF50"

# Tema Laranja/Aviso
.\Exibir-PopupPersonalizado.ps1 -CorHeader "#FF9800" -CorBotaoSim "#FF5722"

# Tema Roxo/Empresa
.\Exibir-PopupPersonalizado.ps1 -CorHeader "#9C27B0" -CorBotaoSim "#673AB7"

# Tema Vermelho/Crítico
.\Exibir-PopupPersonalizado.ps1 -CorHeader "#F44336" -CorBotaoSim "#D32F2F"

# Tema Verde/Sucesso
.\Exibir-PopupPersonalizado.ps1 -CorHeader "#4CAF50" -CorBotaoSim "#388E3C"

# Tema Escuro
.\Exibir-PopupPersonalizado.ps1 -CorHeader "#424242" -CorBotaoSim "#757575"
```

### 🖼️ Adicionar Sua Logo

Para adicionar logo, você precisa editar o módulo `PopupPersonalizado.psm1`:

1. Salve sua logo como `logo.png` na mesma pasta
2. Abra `PopupPersonalizado.psm1` e localize a linha do `IconeHeader`
3. Substitua o TextBlock do emoji por:
```xml
<!-- Substituir esta linha -->
<TextBlock Grid.Column="0" Text="$IconeHeader" .../>

<!-- Por esta -->
<Image Grid.Column="0" Source="logo.png" Width="60" Height="60" Margin="0,0,15,0"/>
```

---

## Método 4: HTML Application (HTA)

Para quem prefere HTML/CSS/JavaScript.

### Exemplo Simples
```powershell
$html = @"
<html>
<head>
<style>
body { font-family: Segoe UI; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }
.container { background: white; padding: 30px; border-radius: 10px; margin: 50px auto; width: 400px; }
button { padding: 10px 20px; margin: 10px; cursor: pointer; }
</style>
<script>
function confirmar() {
    var shell = new ActiveXObject("WScript.Shell");
    shell.Run("shutdown /l /f");
    window.close();
}
</script>
</head>
<body>
<div class="container">
    <h2>Fazer Logoff?</h2>
    <p>Deseja fazer logoff agora?</p>
    <button onclick="confirmar()">Sim</button>
    <button onclick="window.close()">Não</button>
</div>
</body>
</html>
"@

$html | Out-File "$env:TEMP\popup.hta"
Start-Process -FilePath "$env:TEMP\popup.hta"
```

### ✅ Vantagens
- Use HTML/CSS/JavaScript
- Flexibilidade total
- Fácil para quem sabe web

### ❌ Desvantagens
- Aviso de segurança do Windows
- Pode ser bloqueado por antivírus
- Mais complexo de depurar

---

## Comparação de Código

### WScript.Shell (Método Atual)
```powershell
$wshell = New-Object -ComObject WScript.Shell
$resposta = $wshell.Popup("Fazer logoff?", 0, "Titulo", 4 + 32 + 256 + 4096)
# 5 linhas, sem customização visual
```

### WPF (Recomendado para customização)
```powershell
# 150 linhas de XAML
# Customização total de aparência
# Pode adicionar qualquer elemento visual
# Fontes, cores, imagens, layouts, tudo!
```

---

## Recomendações

### Use WScript.Shell quando:
- ✅ Precisa de algo rápido e simples
- ✅ Aparência padrão do Windows é aceitável
- ✅ Só precisa de confirmação básica
- ✅ Quer código mínimo

### Use WPF quando:
- ✅ Precisa adicionar logo da empresa
- ✅ Quer cores da identidade visual
- ✅ Precisa de layout específico
- ✅ Quer impressionar com design moderno
- ✅ Precisa de campos de input customizados

### Use Forms MessageBox quando:
- ✅ Meio termo entre WScript e WPF
- ✅ Precisa de um pouco mais de controle
- ✅ Mas não quer complexidade do WPF

---

## Migração: WScript → WPF

Para migrar seu popup atual para WPF customizado:

1. **Copie** `popup-personalizado-wpf.ps1`
2. **Edite** o XAML para suas cores/logo
3. **Teste** o novo visual
4. **Substitua** chamadas antigas

**Antes:**
```powershell
.\Solicitar-Logoff.ps1 -Titulo "Teste" -Mensagem "Fazer logoff?"
```

**Depois:**
```powershell
.\popup-personalizado-wpf.ps1 -Titulo "Teste" -Mensagem "Fazer logoff?"
```

A lógica permanece a mesma, apenas a aparência muda!

---

## Exemplos de Customização WPF

### Tema Escuro
```xml
<Grid Background="#1E1E1E">
<Border Background="#252526">
<TextBlock Foreground="White"/>
<Button Background="#0E639C" Foreground="White"/>
```

### Tema Empresa (Exemplo)
```xml
<!-- Header com cor da empresa -->
<Border Background="#FF6600">  <!-- Laranja -->

<!-- Logo da empresa -->
<Image Source="empresa-logo.png" Width="80"/>

<!-- Botão com cor primária -->
<Button Background="#FF6600" Foreground="White"/>
```

### Adicionar Ícone na Taskbar
```xml
<Window Icon="icone.ico">
```

---

## Conclusão

**Para seu caso atual (logoff administrativo):**

- Se aparência simples OK → **Manter WScript** ✅ Já funciona bem
- Se quer adicionar logo/cores → **Migrar para WPF** ⭐ Use `popup-personalizado-wpf.ps1`

O WPF permite personalização total mantendo a mesma funcionalidade!