#!/home/mukutk/bin/zsh
# This will not work properly for bash scripts (you must use zsh)
# simple zsh script to generate multiple conformers of a single molecule
# requires openbabel (obabel) and shuf (coreutils)
# the input file must be in .pdb format

# create a number of conformers of a single molecule
# obabel input.pdb -O output.pdb --confab --conf n
# the above command will generate 'n' conformers and saves only the ones that have local minimum energy

#./initial.sh C12H26 CCCCCCCCCCCC 30 O2 O=O 60 0.1


obabel -ismi -opdb --gen3d best <<< $2  > $1.pdb

#First create the directory that will contain all the successfull conformers



# a=$(echo $1|cut -d . -f1)
a=$1


echo $a

mkdir ${a}_conformers_directory

# obabel $1.pdb -O $(echo ${a}_conformers_directory/confs.pdb) --confab --conf 200000 --verbose

obabel $1.pdb -O $(echo ${a}_conformers_directory/confs.pdb) --conformer --weighted --nconf $(($3-1)) --score rmsd --writeconformers

cd ${a}_conformers_directory

echo 'splitting files to ' "$(pwd)"
# the confs.pdb file contains all the successfull conformers. Let's split it into multiple conformed pdb files

grep -n 'COMPND\|END' confs.pdb | cut -d: -f 1 | \
awk -v b="$a" '{if(NR%2) printf "sed -n %d,",$1+1; else printf "%dp confs.pdb > "b"_conformer_%03d.pdb\n", $1-1,NR/2;}' |  bash -sf

# Let's delete the confs.pdb file

rm confs.pdb

# minimize the energy of the generated conformers
for f in *.pdb; do echo " minimizing energy in $f" ;obminimize -c 1e-3 -ff MMFF94 $f > EM_${f}; done
rm ${a}*.pdb

# go back to root directory
cd ..




#Second Molecule

obabel -ismi -opdb --gen3d best <<< $5  > $4.pdb

a=$4


echo $a

mkdir ${a}_conformers_directory

# obabel $4.pdb -O $(echo ${a}_conformers_directory/confs.pdb) --confab --conf 200000 --verbose

obabel $4.pdb -O $(echo ${a}_conformers_directory/confs.pdb) --conformer --weighted --nconf $(($6-1)) --score rmsd --writeconformers

cd ${a}_conformers_directory

echo 'splitting files to ' "$(pwd)"
# the confs.pdb file contains all the successfull conformers. Let's split it into multiple conformed pdb files

grep -n 'COMPND\|END' confs.pdb | cut -d: -f 1 | \
awk -v b="$a" '{if(NR%2) printf "sed -n %d,",$1+1; else printf "%dp confs.pdb > "b"_conformer_%03d.pdb\n", $1-1,NR/2;}' |  bash -sf

# Let's delete the confs.pdb file

rm confs.pdb

# minimize the energy of the generated conformers
for f in *.pdb; do echo " minimizing energy in $f" ;obminimize -c 1e-3 -ff MMFF94 $f > EM_${f}; done
rm ${a}*.pdb

# go back to root directory
cd ..

# prepare pacmole input file
density=$7
dens_rep=$(($density*100))  
dens_rep=$(echo ${dens_rep%.*})

m1="$(obabel  $1.pdb  -osmi  --sort MW+ | cut -d ' ' -f 2)"
m2="$(obabel  $4.pdb  -osmi  --sort MW+ | cut -d ' ' -f 2)"
n1=$3
n2=$6

size=$(((1.0e10)*(($m1*$n1+$m2*$n2)/(6.023e29*$density))**(1.0/3.0)))
echo 'box density  = ' "${7} gm/cc"
echo 'box dimension  = ' "${size} A"

echo 'Creating PACKMOL input file: '

echo "  
        # A mixture of $1 and $4
        # 

        # All the atoms from diferent molecules will be separated at least 2.0
        # Anstroms at the solution.

        tolerance 2.0

        # The file type of input and output files is PDB

        filetype pdb

        # The name of the output file

        output $3$1$6$4.pdb

" > $3$1$6$4.inp

count=$(ls ${1}_conformers_directory | wc -l )

if [ $count -gt 1 ]

then

for i in {1..$3}
do
    file=$(ls ${1}_conformers_directory | shuf -n 1)
   echo "
        structure ./${1}_conformers_directory/$file  
            number 1 
            inside cube 0. 0. 0. $size
        end structure

        " >> $3$1$6$4.inp
done

else
    file=$(ls ${1}_conformers_directory | shuf -n 1)
   echo "
        structure ./${1}_conformers_directory/$file  
            number $3 
            inside cube 0. 0. 0. $size
        end structure

        " >> $3$1$6$4.inp
fi


count=$(ls ${4}_conformers_directory | wc -l )

if [ $count -gt 1 ]

then

for i in {1..$6}
do
    file=$(ls ${4}_conformers_directory | shuf -n 1)
   echo "
        structure ./${4}_conformers_directory/$file  
            number 1 
            inside cube 0. 0. 0. $size
        end structure

        " >> $3$1$6$4.inp
done

else
    file=$(ls ${4}_conformers_directory | shuf -n 1)
   echo "
        structure ./${4}_conformers_directory/$file  
            number $6 
            inside cube 0. 0. 0. $size
        end structure

        " >> $3$1$6$4.inp
fi

echo 'Done '

echo 'Executing PACKMOL: '

packmol < $3$1$6$4.inp
mv $3$1$6$4.inp $3$1_$6$4_0$dens_rep.inp

echo 'Done'

echo "Saving LAMMPS input file => $3$1_$6$4_0$dens_rep.data :  "

obabel  -ipdb $3$1$6$4.pdb -olmpdat | sed -n '/Bonds/q;p' | sed "s/.*xlo.*/0.000000 $size xlo xhi/g" | sed "s/.*ylo.*/0.000000 $size ylo yhi/g" | sed "s/.*zlo.*/0.000000 $size zlo zhi/g" | sed "s/.*bonds.*/0  bonds/g" | sed "s/.*angles.*/0  angles/g"| sed "s/.*dihedrals.*/0  dihedrals/g"| sed "s/.*impropers.*/0  impropers/g"| sed "s/.*bond .*/0  bond types/g" | sed "s/.*angle .*/0  angle types/g"| sed "s/.*dihedral .*/0  dihedral types/g"| sed "s/.*improper .*/0  improper types/g"   > intermediate

lineNumber=$(grep -n "atoms" intermediate | cut -d: -f 2| cut -d " "  -f 1)
key=$(grep -n "Atoms" intermediate|cut -d: -f 1)



head -n $(($key + 1)) intermediate > $3$1_$6$4_0$dens_rep.data  

key=$(expr $key + 2)

lineNumber=$(expr $key + $lineNumber - 1) 



# awk -v start=$key -v end=$lineNumber -v OFS='\t'  'NR>=start && NR<=end {print $1,$3,0.0,$5,$6,$7}' intermediate >> $3$1_$6$4_0$dens_rep.data    

awk -v start=$key -v end=$lineNumber   'NR>=start && NR<=end {printf "%4d\t%d\t%.3f\t%.3f\t%.3f\t%.3f\n", $1,$3,0.0,$5,$6,$7}' intermediate >> $3$1_$6$4_0$dens_rep.data    


rm intermediate

echo 'Done'

echo 'Deleting intermediate files: '
rm -r *_conformers_directory *.pdb *.inp
echo 'Done' 