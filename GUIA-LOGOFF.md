# Guia de Uso - Popup de Logoff

## Visão Geral

Este módulo fornece uma função para exibir um popup modal que pergunta ao usuário se deseja fazer logoff do Windows. Útil para situações onde é necessário que o usuário reinicie sua sessão (ex: após conceder permissões de administrador, atualizar políticas de grupo, etc.).

## Arquivos

- **PopupLogoff.psm1** - Módulo PowerShell com a função `Show-PopupLogoff`
- **Solicitar-Logoff.ps1** - Script de linha de comando que usa o módulo
- **popup-logoff.ps1** - Versão standalone (legado)

## Instalação

Não é necessária instalação. Basta ter os arquivos na mesma pasta.

## Uso Básico

### Método 1: Usando o Script (Mais simples)

```powershell
# Uso básico - mostra popup com mensagem padrão
.\Solicitar-Logoff.ps1

# Com mensagem personalizada
.\Solicitar-Logoff.ps1 -Titulo "Reiniciar Sessao" -Mensagem "Deseja fazer logoff agora?"

# Com timeout de 60 segundos
.\Solicitar-Logoff.ps1 -Timeout 60

# Com delay personalizado antes do logoff
.\Solicitar-Logoff.ps1 -DelayLogoff 5
```

### Método 2: Importando o Módulo Diretamente

```powershell
# Importar o módulo
Import-Module ".\PopupLogoff.psm1"

# Usar a função
Show-PopupLogoff

# Com parâmetros
Show-PopupLogoff -Titulo "Alerta" -Mensagem "Fazer logoff?" -Timeout 30
```

## Parâmetros Disponíveis

| Parâmetro | Tipo | Obrigatório | Padrão | Descrição |
|-----------|------|-------------|--------|-----------|
| `Titulo` | String | Não | "Acesso de Administrador Concedido" | Título da janela do popup |
| `Mensagem` | String | Não | Mensagem padrão completa | Texto exibido no popup |
| `Timeout` | Int | Não | 0 | Segundos até fechar automaticamente (0 = sem timeout) |
| `DelayLogoff` | Int | Não | 3 | Segundos de espera antes de executar o logoff |

## Comportamento

### Botões do Popup

O popup exibe dois botões:

- **Sim** → Executa logoff após o delay configurado
- **Não** → Cancela a operação, nada acontece

**Botão padrão:** O botão **"Não"** tem foco inicial (mais seguro para evitar logoffs acidentais). O usuário pode pressionar Enter para cancelar ou Tab+Enter para confirmar.

### Ícone

- Ícone de **pergunta (?)** para indicar que é uma escolha

### Modalidade

- Popup é **System Modal** (sempre aparece no topo de outras janelas)
- **Bloqueia** a execução do script até o usuário responder

### Retorno

A função retorna:
- `$true` → Se logoff foi executado (usuário clicou "Sim" ou timeout)
- `$false` → Se foi cancelado (usuário clicou "Não")

O script `Solicitar-Logoff.ps1` retorna exit codes:
- `0` → Logoff será executado
- `1` → Logoff cancelado
- `2` → Erro na execução

## Exemplos Práticos

### Exemplo 1: Após Adicionar Usuário ao Grupo de Administradores

```powershell
# Script que adiciona usuario ao grupo de admins
Add-LocalGroupMember -Group "Administradores" -Member "usuario123"

# Solicitar logoff
.\Solicitar-Logoff.ps1 -Titulo "Permissoes Atualizadas" -Mensagem "Usuario adicionado ao grupo de administradores.`n`nFazer logoff para aplicar?"
```

### Exemplo 2: Com Timeout para Ambientes Automatizados

```powershell
# Dar 120 segundos para o usuario decidir, depois faz logoff automaticamente
.\Solicitar-Logoff.ps1 -Timeout 120 -Mensagem "Manutencao agendada em 2 minutos.`n`nFazer logoff agora?"
```

### Exemplo 3: Verificar se Logoff Foi Executado

```powershell
$resultado = Show-PopupLogoff -Titulo "Confirmar" -Mensagem "Fazer logoff?"

if ($resultado) {
    Write-Host "Usuario confirmou o logoff"
    # O logoff já foi executado automaticamente
} else {
    Write-Host "Usuario cancelou"
    # Pode enviar email ou log do cancelamento
}
```

### Exemplo 4: Script de Concessão de Acesso Completo

```powershell
# Script completo para conceder acesso administrativo

param(
    [Parameter(Mandatory=$true)]
    [string]$Usuario
)

try {
    # 1. Adicionar ao grupo de administradores
    Write-Host "Adicionando $Usuario ao grupo de administradores..." -ForegroundColor Cyan
    Add-LocalGroupMember -Group "Administradores" -Member $Usuario

    # 2. Notificar e solicitar logoff
    Write-Host "Acesso concedido! Solicitando logoff..." -ForegroundColor Green

    $mensagemCustom = "Usuario $Usuario foi adicionado ao grupo de Administradores.`n`nPara aplicar as novas permissoes, e necessario fazer logoff e login novamente.`n`nDeseja fazer logoff agora?"

    .\Solicitar-Logoff.ps1 -Titulo "Acesso Administrativo Concedido" -Mensagem $mensagemCustom -Timeout 300

} catch {
    Write-Error "Erro ao conceder acesso: $_"
}
```

## Uso em Scripts Remotos

### Executar em Máquina Remota via PSRemoting

```powershell
# Copiar arquivos para maquina remota
$sessao = New-PSSession -ComputerName "MAQUINA-REMOTA"

Copy-Item ".\PopupLogoff.psm1" -Destination "C:\Temp\" -ToSession $sessao
Copy-Item ".\Solicitar-Logoff.ps1" -Destination "C:\Temp\" -ToSession $sessao

# Executar popup na sessao do usuario logado
Invoke-Command -Session $sessao -ScriptBlock {
    C:\Temp\Solicitar-Logoff.ps1
}

Remove-PSSession $sessao
```

## Cenários de Uso Comuns

### ✅ Quando Usar

- Após adicionar usuário a grupos que requerem nova sessão
- Após aplicar políticas de grupo (GPO)
- Após instalar software que requer reinício de sessão
- Manutenção programada que requer usuário deslogado
- Expiração de sessão por segurança

### ❌ Quando NÃO Usar

- Para reiniciar o computador inteiro (use `shutdown /r` ao invés)
- Para mensagens que não requerem ação imediata (use toast notification)
- Em scripts não-interativos sem usuário logado
- Em serviços Windows ou tarefas agendadas sem contexto de usuário

## Customização Avançada

### Modificar Botão Padrão

Por padrão, o botão **"Não"** tem foco inicial (mais seguro). Para mudar para o botão **"Sim"**:

```powershell
# No PopupLogoff.psm1, modificar a linha do $tipo:
# Remover o 256 para fazer "Sim" ser o padrão
$tipo = 4 + 32 + 4096  # Sem 256 = Sim é padrão
```

Valores para botão padrão:
- `0` → Primeiro botão (Sim)
- `256` → Segundo botão (Não) ← **Configuração atual**
- `512` → Terceiro botão (se houver)

### Modificar Texto dos Botões

**Limitação:** Os textos "Sim" e "Não" são definidos pelo Windows e não podem ser alterados via `WScript.Shell.Popup()`.

**Alternativas:**
1. Usar `Windows.Forms.MessageBox` para mais controle
2. Criar janela WPF customizada
3. Aceitar os botões padrão do Windows

### Adicionar Mais Opções

Se precisar de mais de 2 botões (ex: Sim/Não/Cancelar), modifique o parâmetro `$tipo` no módulo:

```powershell
# No PopupLogoff.psm1, linha do $tipo:
$tipo = 3 + 32 + 4096  # 3 = Sim/Nao/Cancelar

# Adicionar tratamento para retorno 2 (Cancelar)
switch ($resposta) {
    6 { $fazerLogoff = $true }   # Sim
    7 { $fazerLogoff = $false }  # Nao
    2 { $fazerLogoff = $false }  # Cancelar
}
```

## Troubleshooting

### Popup não aparece

**Causa:** Usuário não está logado ou não há sessão interativa
**Solução:** Verificar se há usuário logado: `query user`

### Popup aparece escondido

**Causa:** Já resolvido com System Modal (`4096`)
**Solução:** O código já inclui `4096` para garantir que popup fique no topo

### Logoff não executa

**Causa:** Usuário não tem permissão
**Solução:** Executar script como administrador ou verificar permissões

### Encoding incorreto nos textos

**Causa:** Arquivo não está salvo em Windows-1252
**Solução:** Salvar `PopupLogoff.psm1` e `Solicitar-Logoff.ps1` com encoding Windows-1252 no VS Code

## Diferenças: Módulo vs Script Standalone

### PopupLogoff.psm1 + Solicitar-Logoff.ps1 (Recomendado)

✅ Reutilizável em múltiplos scripts
✅ Melhor organização do código
✅ Help integrado (`Get-Help Show-PopupLogoff`)
✅ Mais fácil de manter

### popup-logoff.ps1 (Legado)

✅ Arquivo único, mais simples de distribuir
❌ Menos flexível
❌ Sem help integrado

## Integração com Outros Módulos

### Usar junto com WindowsNotification.psm1

```powershell
# Primeiro mostra toast notification
Import-Module ".\WindowsNotification.psm1"
Show-NotificacaoWindows -Mensagem "Acesso concedido!" -Titulo "Sucesso"

# Aguardar um pouco
Start-Sleep -Seconds 3

# Depois mostrar popup de logoff
Import-Module ".\PopupLogoff.psm1"
Show-PopupLogoff
```

## Segurança

⚠️ **Atenção:**
- Este script executa **logoff forçado** (`shutdown /l /f`)
- Aplicativos não salvos **perderão dados**
- Recomenda-se avisar o usuário claramente na mensagem
- Considere aumentar o `DelayLogoff` para dar tempo de salvar trabalhos

## Suporte e Contribuição

Para reportar problemas ou sugerir melhorias:
1. Verifique este guia primeiro
2. Teste com `-Verbose` para ver detalhes de execução
3. Documente o comportamento esperado vs. observado

## Licença

Este módulo é fornecido como-está, sem garantias.