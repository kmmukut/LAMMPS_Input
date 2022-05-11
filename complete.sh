#!/bin/zsh
# This will create a new case directory with initial configuration (you must use zsh)

# Create the initial simulation directory for ReaxFF simulation
# Requires the complete testSetup directory

# ./complete.sh C2H4 C=C 750 O2 O=O 642 0.1 E_165_35_1_010 

echo "Creating the initial configuration file: $8"


density=$7
dens_rep=$(($density*100))  
dens_rep=$(echo ${dens_rep%.*})

./initial.sh $1 $2 $3 $4 $5 $6 $7 

./caseSetup.sh $8 

mv $3$1_$6$4_0$dens_rep.data ./$8/$8.data



echo "Now checking the accuracy of the system"

echo -e '\033[0;36m Total number of atoms check:  ' 

a=$(obabel -h "-:$2" -o smiles --append "atoms"  |  awk '{ print $2 }' )

b=$(obabel -h "-:$5" -o smiles --append "atoms"  |  awk '{ print $2 }' )

totalAtomCalc=$(($a*$3+$b*$6 ))
totalAtomAct=$(grep "atoms" ./$8/$8.data | cut -d  " " -f 1)

if [ $totalAtomAct != $totalAtomCalc ]; then
    echo -e '\033[31m ERROR: Total number of atom is not matching ' 
else
    echo -e '\033[0;32m CHECK SUCCESSFUL: Total number of atom is matching ' 
fi

echo -e '\033[0;36m Density check: ' 
              

m1=$(obabel -h "-:$2" -o smiles --append "MW"  |  awk '{ print $2 }' )
m2=$(obabel -h "-:$5" -o smiles --append "MW"  |  awk '{ print $2 }' )
n1=$3
n2=$6

sizeCalc=$(((1.0e10)*(($m1*$n1+$m2*$n2)/(6.023e29*$density))**(1.0/3.0)))
sizeAct=$(grep "xlo" ./$8/$8.data | cut -d ' ' -f 2)

if [ $sizeAct != $sizeCalc ]; then
    echo -e '\033[31m ERROR: Density is not matching ' 
else
    echo -e '\033[0;32m CHECK SUCCESSFUL: Density is matching ' 
fi
