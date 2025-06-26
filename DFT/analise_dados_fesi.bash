#!/bin/bash

# Caminho até a pasta dos arquivos .out
caminho="/home/pedro/Documents/est_eletronica/QuantumEspresso/FeSi/outputs"

# Arquivo de saída
saida="dados_energia.dat"
echo "# ecutwfc (Ry)     Energia Total (Ry)" > "$saida"

# Loop nos arquivos .out
for file in "$caminho"/scf_*Ry.out; do
    # Verifica se o arquivo existe
    if [[ -f "$file" ]]; then
        # Extrai ecutwfc
        ecut=$(grep "ecut=" "$file" | head -1 | awk -F'ecut=' '{print $2}' | awk '{print $1}')

        # Extrai energia total
        energia=$(grep ! $file | gawk '{print $5}')
        if [[ -n "$ecut" && -n "$energia" ]]; then
            printf "%-16s %s\n" "$ecut" "$energia" >> "$saida"
        else
            echo "Aviso: Dados ausentes em $file" >&2
        fi
    else
        echo "Aviso: Arquivo não encontrado: $file" >&2
    fi
done

echo "Arquivo '$saida' gerado com sucesso."
