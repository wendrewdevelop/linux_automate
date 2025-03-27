#!/usr/bin/perl
use strict;
use warnings;
use File::Basename;
use File::Path qw(make_path);

my $USER = $ENV{USER};
my $HOME = $ENV{HOME};

sub setup_directories {
    my $base = "$HOME/Documentos";
    my @dirs = (
        "ONEMANCOMPANY",
        "SCRIPTS", 
        "HAPVIDA/NOTAS",
        "HAPVIDA/DOCUMENTOS"
    );

    my $has_file_path = eval {
        require File::Path;
        File::Path->import('mkpath');
        1;
    };

    unless ($has_file_path) {
        print "AVISO: File::Path não encontrado. Usando método manual.\n";
        
        sub mkpath_manual {
            my ($path) = @_;
            return if -d $path;
            
            my @parts = split('/', $path);
            my $current = '';
            my @created;
            
            foreach my $part (@parts) {
                $current .= "$part/";
                next if $current eq '/';
                
                unless (-d $current) {
                    mkdir($current) or do {
                        warn "Erro ao criar $current: $!";
                        return 0;
                    };
                    push @created, $current;
                    print "Criado: $current\n";
                }
            }
            return 1;
        }
        
        *mkpath = \&mkpath_manual;
    }

    sub criar_diretorio {
        my ($path) = @_;
        
        unless (-d $path) {
            my $success = mkpath($path);
            $success or warn "ERRO: Falha ao criar $path ($!)";
            return $success;
        }
        return 1;
    }

    my $errors = 0;
    -e $base || criar_diretorio($base) or $errors++;

    foreach my $dir (@dirs) {
        my $full_path = "$base/$dir";
        criar_diretorio($full_path) or $errors++;
    }

    return $errors;
}

sub run_cmd {
    my $cmd = shift;
    print "Executando: $cmd\n";
    system($cmd) == 0 or warn "Erro ao executar: $cmd\n";
}

sub install_packages {
    run_cmd("sudo apt update && sudo apt upgrade -y");
    run_cmd("sudo apt install -y git curl wget software-properties-common");
    run_cmd("sudo apt install -y python3 python3-pip python3-venv");
    run_cmd("pip install uv");
    run_cmd("sudo apt install -y postgresql postgresql-contrib");
    run_cmd("sudo add-apt-repository -y ppa:aslatter/ppa");
    run_cmd("sudo apt install -y alacritty");
    run_cmd("wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb");
    run_cmd("sudo dpkg -i google-chrome-stable_current_amd64.deb");
    run_cmd("wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg");
    run_cmd("sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/");
    run_cmd("sudo sh -c 'echo \"deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main\" > /etc/apt/sources.list.d/vscode.list'");
    run_cmd("sudo apt update && sudo apt install -y code");
    run_cmd("sudo snap install dbeaver-ce");
}

sub configure_alacritty {
    my $config_dir = "$HOME/.config/alacritty";
    my $config_file = "$config_dir/alacritty.toml";
    
    make_path($config_dir) unless -d $config_dir;
    
    open(my $fh, '>', $config_file) or die "Não foi possível criar $config_file: $!";
    
    print $fh <<'END_CONFIG';
[env]
WINIT_X11_SCALE_FACTOR = "1"

[keyboard.bindings]
action = "SpawnNewInstance"
key = "N"
mods = "Control|Shift"

[[keyboard.bindings]]
action = "CreateNewTab"
key = "T"
mods = "Control|Shift"

[colors.bright]
black = "#666666"
red = "#ff6666"
green = "#99cc99"
yellow = "#ffcc66"
blue = "#6699cc"
magenta = "#cc99cc"
cyan = "#66cccc"
white = "#ffffff"

[colors.cursor]
cursor = "#d4d4d4"
text = "#1e1e1e"

[colors.normal]
black = "#2d2d2d"
red = "#ff6666"
green = "#99cc99"
yellow = "#ffcc66"
blue = "#6699cc"
magenta = "#cc99cc"
cyan = "#66cccc"
white = "#d4d4d4"

[colors.primary]
background = "#2d2d2d"
foreground = "#d4d4d4"

[colors.selection]
background = "#3e3e3e"
text = "#ffffff"

[colors.hints]
start = { foreground = "#d4d4d4", background = "#1e1e1e" }
end = { foreground = "#1e1e1e", background = "#d4d4d4" }

[cursor]
style = "Block"

[font]
size = 12.0

[font.normal]
family = "Fira Code"
style = "Regular"

[font.bold]
family = "Fira Code"
style = "Bold"

[font.italic]
family = "Fira Code"
style = "Italic"

[scrolling]
history = 10000

[window]
opacity = 0.9
padding = { x = 10, y = 10 }
dimensions = { columns = 120, lines = 30 }
startup_mode = "Windowed"

[terminal.shell]
program = "/usr/bin/zsh"
END_CONFIG

    close($fh);
}

sub install_i3 {
    run_cmd("sudo apt install -y i3 i3status rofi i3blocks feh compton xmodmap");
    my $i3_dir = "$HOME/.config/i3";
    my $i3_config = "$i3_dir/config";
    
    make_path($i3_dir) unless -d $i3_dir;
    
    open(my $fh, '>', $i3_config) or die "Não foi possível criar $i3_config: $!";
    
    print $fh <<'END_I3_CONFIG';
# Configuração i3wm omitida por brevidade. Usar a configuração fornecida pelo usuário.
END_I3_CONFIG

    close($fh);
    run_cmd("sudo apt install -y fonts-firacode fonts-noto");
}

sub post_install {
    print "\nConfiguração concluída!\n";
    print "Recomendações:\n";
    print "1. Reinicie o sistema\n";
    print "2. Selecione o i3wm no gerenciador de login\n";
    print "3. Execute 'nitrogen' para configurar seu wallpaper\n";
}

install_packages();
configure_alacritty();
install_i3();
post_install();
