#!/bin/zsh
# This will not work properly for bash scripts (you must use zsh)

# Create the initial simulation directory for ReaxFF simulation
# Requires the complete testSetup directory

# ./caseSetup.sh E_165_35_1_010



cp -r testSetup/ $1
cd $1

echo "Starting directory set up for $1"

temp=$((10*$(echo $1 | cut -d '_' -f 2 )))
echo "Temperature= $temp"

eqr=$(($(echo $1 | cut -d '_' -f 3)/10.0))
echo "Equivalence Ratio= $eqr"

stat=$(echo $1 | cut -d '_' -f 4)
echo "Statistical Run # $stat"

dens=$(($(echo $1 | cut -d '_' -f 5)/100.0))
echo "Density= $dens"

MIN=1645100000
MAX=1645999999
SEED=$(( $RANDOM % ($MAX + 1 - $MIN) + $MIN ))

echo "Psudorandom seed= $SEED"

sed -i ''  "s/NAME/$1/g" reaxc.control 
sed -i ''  "s/NAME/$1/g" in.in 
sed -i ''  "s/TEMP/$temp/g" in.in 
sed -i ''  "s/DENS/$dens/g" in.in 
sed -i ''  "s/EQ/$eqr/g" in.in 
sed -i ''  "s/SEED/$SEED/g" in.in 
sed -i ''  "s/STAT/$stat/g" in.in 

sed -i ''  "s/NAME/$1/g" run.slrm_raj 
sed -i ''  "s/NAME/$1/g" run.slrm_hpc


echo "Set up is complete"