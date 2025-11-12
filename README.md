# Sistema de Notificações PowerShell para Windows

Este projeto fornece um sistema robusto de notificações para Windows 11/10 usando PowerShell, com suporte a notificações toast modernas e fallback para balões do sistema.

## ⚠️ IMPORTANTE: Codificação de Arquivos

**Para que os acentos e caracteres especiais do português funcionem corretamente, todos os arquivos `.ps1` e `.psm1` DEVEM ser salvos com codificação Windows-1252 (também conhecida como ANSI ou Latin-1).**

### Por que Windows-1252?

O console PowerShell no Windows usa codificação CP850/CP437 (Europa Ocidental DOS) por padrão. Arquivos salvos em UTF-8 terão caracteres portugueses (ç, ã, õ, á, etc.) exibidos incorretamente como `��ǜo` ou `Ã§Ã£o`.

### Como configurar no VS Code:

1. Abra o arquivo `.ps1` ou `.psm1`
2. No canto inferior direito, clique no encoding atual (normalmente "UTF-8")
3. Selecione "Save with Encoding" (Salvar com Codificação)
4. Escolha "Western (Windows 1252)"

### Como configurar em outros editores:

- **Notepad++**: Menu Encoding > Character Sets > Western European > Windows-1252
- **Sublime Text**: File > Save with Encoding > Western (Windows 1252)
- **Notepad**: Automático ao salvar (usa ANSI por padrão)

### Verificação:

Após salvar com Windows-1252, strings como `"notificação"` devem aparecer corretamente no console e nas notificações.

## Arquivos Incluídos

- **WindowsNotification.psm1** - Módulo PowerShell com funções de notificação
- **Show-Popup.ps1** - Script de linha de comando para enviar notificações
- **Check-NotificationSettings.ps1** - Script de diagnóstico (opcional)

## Como Usar

### Uso Básico

```powershell
# Notificação simples
.\Show-Popup.ps1 "Sua mensagem aqui"

# Notificação com título personalizado
.\Show-Popup.ps1 "Tarefa concluída com sucesso!" "Status do Sistema"

# Usando parâmetros posicionais
.\Show-Popup.ps1 "Mensagem" "Título"
```

### Opções Avançadas

```powershell
# Notificação persistente (só desaparece quando fechada manualmente)
.\Show-Popup.ps1 "Lembrete importante!" "Urgente" -Sticky

# Forçar uso do método fallback (balão do sistema)
.\Show-Popup.ps1 "Mensagem de fallback" "Teste" -UseFallback

# Combinação: notificação persistente com fallback
.\Show-Popup.ps1 "Aviso crítico" "Sistema" -Sticky -UseFallback

# Com saída detalhada para depuração
.\Show-Popup.ps1 "Mensagem de teste" "Debug" -Verbose
```

### Parâmetros Disponíveis

| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `Message` | String | Sim | Texto da notificação |
| `Title` | String | Não | Título da notificação (padrão: "Notification") |
| `-Sticky` | Switch | Não | Torna a notificação persistente |
| `-UseFallback` | Switch | Não | Force o uso de balões do sistema |
| `-Verbose` | Switch | Não | Exibe informações detalhadas |

## Uso Direto do Módulo

Você também pode importar o módulo diretamente em seus scripts:

```powershell
# Importar o módulo
Import-Module ".\WindowsNotification.psm1"

# Usar as funções
Show-WindowsNotification -Message "Mensagem" -Title "Título"
Show-WindowsNotification -Message "Lembrete" -Title "Importante" -Sticky
```

## Métodos e Tecnologias Utilizadas

### 1. Notificações Toast (Método Principal)

**Tecnologia:** Windows Runtime (WinRT) Toast Notification API

**Como funciona:**
- Utiliza a API nativa do Windows 10/11 para notificações modernas
- Registra automaticamente o PowerShell como aplicativo de notificação no registro do Windows
- Cria templates XML para as notificações com formatação rica
- Suporta diferentes cenários (normal vs. lembrete persistente)

**Vantagens:**
- Integração completa com o Centro de Ações do Windows
- Suporte a botões, imagens e formatação rica
- Notificações persistentes permanecem até serem fechadas manualmente
- Aparência nativa e moderna

**Registro Automático:**
O sistema registra automaticamente o PowerShell em:
```
HKCU:\SOFTWARE\Classes\AppUserModelId\PowerShell.Notifications
```

### 2. Notificações Balão (Método Fallback)

**Tecnologia:** Windows Forms NotifyIcon (.NET Framework)

**Como funciona:**
- Usa a API legacy do .NET Framework para balões do sistema
- Cria temporariamente um ícone na bandeja do sistema
- Exibe balões tooltip que aparecem próximo à bandeja

**Vantagens:**
- Funciona independente das configurações de notificação do Windows
- Não requer registro de aplicativo
- Compatível com versões mais antigas do Windows
- Mais confiável em ambientes corporativos restritivos

**Limitações:**
- Aparência menos moderna
- Não persiste no Centro de Ações
- Duração limitada (máximo 30 segundos para modo sticky)

### 3. Estratégia de Fallback Múltiplo

O sistema tenta várias abordagens em ordem de prioridade:

1. **ID de App Registrado** - `PowerShell.Notifications` (criado automaticamente)
2. **IDs Nativos** - `Microsoft.Windows.PowerShell`, `Windows.PowerShell`
3. **Windows Terminal** - Para usuários do Terminal moderno
4. **Caminho Legacy** - Para instalações antigas do PowerShell
5. **Fallback Final** - Notificações balão (.NET Forms)

### 4. Tratamento de Notificações Persistentes

**Notificações Normais:**
```xml
<toast activationType="foreground">
  <visual>...</visual>
  <audio silent="false"/>
</toast>
```

**Notificações Persistentes (Sticky):**
```xml
<toast scenario="reminder" activationType="foreground">
  <visual>...</visual>
  <actions>
    <action activationType="system" arguments="dismiss" content="Close"/>
  </actions>
  <audio silent="false"/>
</toast>
```

O atributo `scenario="reminder"` instrui o Windows a tratar a notificação como um lembrete persistente.

## Por Que Esta Abordagem?

### Robustez
- **Múltiplos métodos** garantem que as notificações funcionem em diferentes configurações
- **Registro automático** elimina a necessidade de configuração manual
- **Tratamento de erros** robusto com fallbacks inteligentes

### Compatibilidade
- **Windows 10/11** - Suporte completo a toast notifications modernas
- **Ambientes corporativos** - Fallback para balões quando políticas bloqueiam toast
- **PowerShell Core e Windows PowerShell** - Funciona em ambas as versões

### Facilidade de Uso
- **Interface simples** - Um comando para casos básicos
- **Opções avançadas** disponíveis quando necessário
- **Autodocumentação** com help integrado

## Solução de Problemas

Se as notificações toast não aparecerem:

1. **Verificar configurações do Windows:**
   - Configurações > Sistema > Notificações (deve estar habilitado)
   - Verificar se o Foco Assistido não está bloqueando

2. **Tentar o fallback:**
   ```powershell
   .\Show-Popup.ps1 "Teste" "Fallback" -UseFallback
   ```

3. **Executar diagnóstico:**
   ```powershell
   .\Check-NotificationSettings.ps1
   ```

## Exemplos Práticos

```powershell
# Notificação de conclusão de script
.\Show-Popup.ps1 "Backup concluído com sucesso!" "Sistema de Backup"

# Lembrete persistente
.\Show-Popup.ps1 "Reunião em 15 minutos" "Agenda" -Sticky

# Alerta crítico com fallback garantido
.\Show-Popup.ps1 "Espaço em disco baixo!" "Alerta do Sistema" -UseFallback -Sticky

# Notificação de status de longa duração
.\Show-Popup.ps1 "Download de 10GB em progresso..." "Download Manager" -Sticky
```

Este sistema fornece uma solução completa e robusta para notificações em scripts PowerShell, adequada tanto para uso pessoal quanto em ambientes corporativos.