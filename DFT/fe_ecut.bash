#!/bin/bash

# ========== CONFIGURAÇÕES ==========
ecut_start=10
ecut_step=5
ecut_max=50       # Adicionado valor máximo de segurança
thresh=0.00001

mkdir -p outputs

previous_energy=0
converged=false

ecutwfc=${ecut_start}

while [ "$ecutwfc" -le "$ecut_max" ]; do
    input_file="scf_Fe-CCC_${ecutwfc}Ry.in"
    output_file="outputs/scf_Fe-CCC_${ecutwfc}Ry.out"

    echo ">>> Rodando SCF com ecutwfc = ${ecutwfc} Ry"

    cat > ${input_file} <<EOF
&CONTROL
    calculation = 'scf'
    title = 'Fe-CCC'
    outdir = './tmp/'
    prefix = 'Fe-CCC'
    etot_conv_thr = 1d-5
    pseudo_dir = '../pseudos/'
/
&SYSTEM
    ibrav = 3
    celldm(1) = 5.4046163273
    nat = 1
    ntyp = 1
    nspin = 2
    starting_magnetization(1) = 2.5
    ecutwfc = ${ecutwfc}
    occupations = 'smearing'
    smearing = 'mv'
    degauss = 0.001
/
&ELECTRONS
/

ATOMIC_SPECIES
 Fe 55.845 fe_pbe_v1.5.uspp.F.UPF

ATOMIC_POSITIONS crystal
 Fe 0.0 0.0 0.0

K_POINTS automatic
20 20 20 1 1 1
EOF

    pw.x < ${input_file} > ${output_file}

    # Extrair energia total
    total_energy=$(grep "! *total energy" ${output_file} | tail -1 | awk '{print $5}')

    if [ -z "$total_energy" ]; then
        echo "❌ Erro: energia não encontrada em ${output_file}"
        exit 1
    fi

    echo ">>> Energia total: $total_energy Ry"

    # Calcular diferença com a anterior
    if [ "$ecutwfc" -ne "$ecut_start" ]; then
        diff=$(echo "scale=6; ${previous_energy} - ${total_energy}" | bc | tr -d -)
        echo ">>> Diferença com anterior: $diff Ry"

        converged_check=$(echo "$diff < $thresh" | bc)
        if [ "$converged_check" -eq 1 ]; then
            echo "Convergência atingida com ecutwfc = ${ecutwfc} Ry"
            converged=true
            break
        fi
    fi

    previous_energy=$total_energy
    ecutwfc=$((ecutwfc + ecut_step))
done

if [ "$converged" = false ]; then
    echo "Energia de corte não convergiu até ecutwfc = ${ecut_max} Ry"
else
    echo "Energia final convergida: ${total_energy} Ry"
fi
