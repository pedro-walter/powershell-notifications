function Show-PopupPersonalizado {
    <#
    .SYNOPSIS
    Exibe popup totalmente customizado usando WPF com suporte a logoff automatico.

    .DESCRIPTION
    Mostra uma janela WPF moderna com personalizacao completa de cores, textos,
    icones e layout. Suporta acao de logoff quando usuario confirma.

    .PARAMETER Titulo
    Titulo exibido no header da janela

    .PARAMETER Mensagem
    Mensagem principal exibida no popup

    .PARAMETER Subtexto
    Texto secundario/explicativo abaixo da mensagem principal

    .PARAMETER TextoBotaoSim
    Texto do botao de confirmacao (padrao: "Fazer Logoff")

    .PARAMETER TextoBotaoNao
    Texto do botao de cancelamento (padrao: "Agora Nao")

    .PARAMETER CorHeader
    Cor do header em formato hexadecimal (padrao: "#2196F3" - azul)

    .PARAMETER CorBotaoSim
    Cor do botao de confirmacao (padrao: "#4CAF50" - verde)

    .PARAMETER IconeHeader
    Codigo Unicode do emoji/icone do header (padrao: "&#x1F512;" - cadeado)

    .PARAMETER ExecutarLogoff
    Se $true, executa logoff quando usuario confirma. Se $false, apenas retorna resultado.

    .PARAMETER DelayLogoff
    Tempo de espera em segundos antes de executar o logoff

    .EXAMPLE
    Show-PopupPersonalizado
    Exibe popup com configuracoes padrao

    .EXAMPLE
    Show-PopupPersonalizado -Titulo "Manutencao" -CorHeader "#FF9800"
    Popup com header laranja

    .EXAMPLE
    Show-PopupPersonalizado -ExecutarLogoff $false
    Apenas exibe popup sem executar logoff, retorna $true/$false

    .OUTPUTS
    Retorna $true se usuario confirmou, $false se cancelou
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Titulo = "Acesso de Administrador Concedido",

        [Parameter(Mandatory = $false)]
        [string]$Mensagem = "Seu acesso de administrador foi concedido com sucesso!",

        [Parameter(Mandatory = $false)]
        [string]$Subtexto = "Para aplicar as permissoes, e necessario fazer logoff e login novamente.",

        [Parameter(Mandatory = $false)]
        [string]$TextoBotaoSim = "Fazer Logoff",

        [Parameter(Mandatory = $false)]
        [string]$TextoBotaoNao = "Agora Nao",

        [Parameter(Mandatory = $false)]
        [string]$CorHeader = "#2196F3",

        [Parameter(Mandatory = $false)]
        [string]$CorBotaoSim = "#4CAF50",

        [Parameter(Mandatory = $false)]
        [string]$IconeHeader = "&#x1F512;",

        [Parameter(Mandatory = $false)]
        [bool]$ExecutarLogoff = $true,

        [Parameter(Mandatory = $false)]
        [int]$DelayLogoff = 3
    )

    try {
        Add-Type -AssemblyName PresentationFramework
        Add-Type -AssemblyName PresentationCore
        Add-Type -AssemblyName WindowsBase

        # Definir o XAML (layout da janela)
        [xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="$Titulo"
    Height="300" Width="500"
    WindowStartupLocation="CenterScreen"
    ResizeMode="NoResize"
    WindowStyle="SingleBorderWindow"
    Topmost="True"
    ShowInTaskbar="True">

    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Padding" Value="15,8"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>
    </Window.Resources>

    <Grid Background="#F5F5F5">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Header com gradiente -->
        <Border Grid.Row="0" Background="$CorHeader" Padding="20,15">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <!-- Icone (Unicode) -->
                <TextBlock Grid.Column="0"
                           Text="$IconeHeader"
                           FontSize="40"
                           Margin="0,0,15,0"
                           VerticalAlignment="Center"/>

                <!-- Titulo -->
                <TextBlock Grid.Column="1"
                           Text="$Titulo"
                           FontSize="20"
                           FontWeight="Bold"
                           Foreground="White"
                           VerticalAlignment="Center"/>
            </Grid>
        </Border>

        <!-- Conteudo -->
        <StackPanel Grid.Row="1" Margin="30,20">
            <TextBlock Text="$Mensagem"
                       FontSize="16"
                       FontWeight="SemiBold"
                       TextWrapping="Wrap"
                       Margin="0,0,0,15"/>

            <TextBlock Text="$Subtexto"
                       FontSize="14"
                       Foreground="#666"
                       TextWrapping="Wrap"
                       Margin="0,0,0,20"/>

            <Border BorderBrush="$CorHeader"
                    BorderThickness="1"
                    CornerRadius="5"
                    Background="#E3F2FD"
                    Padding="15,10">
                <StackPanel Orientation="Horizontal">
                    <TextBlock Text="&#x26A0;" FontSize="20" Margin="0,0,10,0" Foreground="#FF9800"/>
                    <TextBlock Text="Todos os aplicativos abertos serao fechados."
                               FontSize="12"
                               Foreground="#333"
                               TextWrapping="Wrap"/>
                </StackPanel>
            </Border>
        </StackPanel>

        <!-- Rodape com botoes -->
        <Border Grid.Row="2"
                Background="White"
                BorderBrush="#DDD"
                BorderThickness="0,1,0,0"
                Padding="20,15">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <Button Name="btnNao"
                        Grid.Column="1"
                        Content="$TextoBotaoNao"
                        Background="#E0E0E0"
                        MinWidth="120"/>

                <Button Name="btnSim"
                        Grid.Column="2"
                        Content="$TextoBotaoSim"
                        Background="$CorBotaoSim"
                        Foreground="White"
                        MinWidth="120"/>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

        Write-Verbose "Criando janela WPF..."

        # Criar a janela
        $reader = New-Object System.Xml.XmlNodeReader $xaml
        $window = [Windows.Markup.XamlReader]::Load($reader)

        # Obter referencias dos botoes
        $btnSim = $window.FindName("btnSim")
        $btnNao = $window.FindName("btnNao")

        # Variavel para resultado
        $resultado = $false

        # Eventos dos botoes
        $btnSim.Add_Click({
            $script:resultado = $true
            $window.Close()
        })

        $btnNao.Add_Click({
            $script:resultado = $false
            $window.Close()
        })

        # Fazer botao "Nao" ter foco inicial
        $btnNao.Focus()

        Write-Verbose "Exibindo popup personalizado..."

        # Exibir janela (modal)
        $window.ShowDialog() | Out-Null

        # Processar resultado
        if ($resultado -and $ExecutarLogoff) {
            Write-Verbose "Usuario confirmou - executando logoff em $DelayLogoff segundos..."
            Start-Sleep -Seconds $DelayLogoff
            shutdown /l /f
            Write-Verbose "Comando de logoff enviado!"
        } elseif ($resultado) {
            Write-Verbose "Usuario confirmou (logoff nao sera executado - ExecutarLogoff=$ExecutarLogoff)"
        } else {
            Write-Verbose "Usuario cancelou"
        }

        return $resultado
    }
    catch {
        Write-Error "Erro ao exibir popup personalizado: $_"
        return $false
    }
}

Export-ModuleMember -Function Show-PopupPersonalizado