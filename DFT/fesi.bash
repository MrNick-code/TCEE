#!/bin/bash

# ========== CONFIGURAÇÕES ==========
ecutrho_ratio=8
ecut_start=20
ecut_step=5
thresh=0.001
a0=4.40

mkdir -p outputs

previous_energy=0
converged=false

ecutwfc=${ecut_start}

while [ "$ecutwfc" -le "$ecut_max" ]; do
    ecutrho=$(echo "${ecutwfc} * ${ecutrho_ratio}" | bc)
    input_file="scf_${ecutwfc}Ry.in"
    output_file="outputs/scf_${ecutwfc}Ry.out"

    echo ">>> Rodando SCF com ecutwfc = ${ecutwfc} Ry"

    cat > ${input_file} <<EOF
&CONTROL
  calculation = 'scf'
  title = 'FeSi'
  prefix = 'fesi-sc'
  outdir = './tmp/'
  etot_conv_thr = 1d-5
  nspin = 2
  pseudo_dir = './pseudos/'
/

&SYSTEM
  ibrav = 1 # ver dps
  celldm(1) = $a0
  nat = 1 # ver dps
  ntyp = 2
  ecutwfc = ${ecutwfc}
  ecutrho = ${ecutrho},
  occupations = 'smearing'
  smearing = 'mv'
  degauss = 0.001
/

&ELECTRONS
/
&IONS
/
&CELL
    cell_dofree  = 'ibrav'
/

ATOMIC_SPECIES
Fe  55.845  fe_pbe_v1.5.uspp.F.UPF
Si  28.0855 si_pbe_v1.uspp.F.UPF

ATOMIC_POSITIONS crystal
Fe  0.863088  0.636912  0.363088
Si  0.158698  0.341302  0.658698

K_POINTS automatic
20 20 20 1 1 1
EOF

    pw.x < ${input_file} > ${output_file}

    # Extrair energia total
    total_energy=$(grep "! *total energy" ${output_file} | tail -1 | awk '{print $5}')

    if [ -z "$total_energy" ]; then
        echo "Erro: energia não encontrada em ${output_file}"
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

