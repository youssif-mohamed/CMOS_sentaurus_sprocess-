################################
# 2D CMOS 90nm technology node #
#     credits to:              #
#     Youssif Rabie            #
#      6/20/2021               #
################################
math coord.ucs

#Declare intial grid (1.2 <um> * 1.5<um>)

#------ X-axis (up to down) ---------#
line x location= 0.0      spacing= 3.0<nm>  tag= SiTop        
line x location= 60.0<nm> spacing= 20.0<nm>                    
line x location= 0.5<um>  spacing= 120.0<nm>                      
line x location= 1.2<um>  spacing= 0.5<um> tag= SiBottom                        


#------ Y-axis (left to right) ---------#
line y location= 0.0      spacing= 20.0<nm> tag= Left         
line y location= 1.5<um> spacing=20.0<nm>  tag= Right


#------- Silicon substrate definition ------#
region Silicon xlo= SiTop xhi= SiBottom ylo= Left yhi= Right

#---------- Initialize the simulation -----------#
init concentration= 6.0e+16<cm-3> field= Boron

AdvancedCalibration

#---- Screen shot of the wafer ----#
struct tdr= CMOS_0

#------- Define all used masks ---------#
mask name = STI  segments = {0.225 0.525 0.975 1.275} negative

mask name = NMOS  segments = {-0.1 0.975 1.275 1.5} negative

mask name = PMOS segments = {-0.1 0.225 0.525 1.5} negative

mask name= gate_mask segments = {-0.1 0.330 0.420 1.080 1.170 1.5} negative

mask name = n-well segments = {-0.1 0.225 0.330 0.420 0.525 1.5} negative

mask name= p-well segments = {-0.1 0.975 1.080 1.170 1.275 1.5} negative

#------ Shallow Trench Isolation ------#
# 1- Pad Oxide Growth #
# clear previous gas_flow #
gas_flow clear

# Define inert gas_flow #
gas_flow name= O2_0.1_N2_10 pressure= 1.0<atm> flowO2= 0.1<l/min>  flowN2= 10.0<l/min>

# Define oxygen gas_flow #
gas_flow name= O2 pressure= 1.0<atm>  flowO2= 1.0<l/min>

# clear previous PadOxide if any #
temp_ramp name= PadOxide clear

# --- Define ramping temperatures ----#

# 1- temperature will rise from 700 c to 1050 c with rate 75 c per second #
temp_ramp name= PadOxide time= (1050.0-700.0)/75<s> \
temperature= 700.0<C> ramprate= 75<K/s> gas.flow= O2_0.1_N2_10

# 2- temperature will be constant at 1050 c for 5 min #
temp_ramp name= PadOxide time= 5<min> \
temperature= 1050.0<C> hold                gas.flow= O2

# 3- temperature will decrease from 1050 c to 700 c with rate 75 c per second #
temp_ramp name= PadOxide time= (1050.0-700.0)/20<s> \
temperature= 1050.0<C> ramprate= -20<K/s> gas.flow= O2_0.1_N2_10

#---- Using the predefined ramping temperatures to diffuse heat into the wafer -----#
diffuse temp.ramp= PadOxide

# ---- View the oxide Thickness in the terminal ----#
set PadOxThick [MeasureOx Silicon 2 0.0 ]
puts "Thickness of PadOx is: $PadOxThick um"
struct tdr= CMOS_1

#--- Nitride layer deposition ---#
# create a variable NitrideThick (hard mask)#
set NitrideThick 0.1<um> 
# This command deposit NitrideThick with thickness NitrideThick
deposit Nitride isotropic thickness= $NitrideThick  

struct tdr= CMOS_2

#--- STI Lithography ---#

photo mask = STI thickness = 0.1
struct tdr= CMOS_3

#--- Shallow trench etch ----#
# $NitrideThick*1.5 
etch Nitride anisotropic thickness= 0.15

struct tdr= CMOS_4
# $PadOxThick*1.5
etch Oxide anisotropic thickness= 0.15
strip      Photoresist

struct tdr= CMOS_5

set TrenchAngle 90.0 
set TrenchDepth 0.3


etch Silicon type= trapezoidal thickness= $TrenchDepth angle = $TrenchAngle 


struct tdr= CMOS_6

#--- Oxide liner growth ---#

gas_flow clear
gas_flow name= O2 pressure = 1.0<atm>  flowO2= 1.0<l/min>
temp_ramp name= Liner_Oxide clear
temp_ramp name= Liner_Oxide time = 3<min> temperature= 1050.0<C> gas.flow= O2 
diffuse temp.ramp= Liner_Oxide

struct tdr= CMOS_7

#--- TEOS deposition/CMP ---#
deposit Oxide isotropic thickness = 0.5
struct tdr= CMOS_8

etch cmp coord= -0.1
struct tdr= CMOS_9

#--- Nitride strip/reflect ----#

strip Nitride

struct tdr= CMOS_10


#------- Active region creation -------#
photo mask = NMOS thickness = 1

# energy = 100kev so  strugle is 0.025um
implant  phosphorus  dose= 3.75e12<cm-2>  energy= 100<keV> tilt= 0 rotation= 0  
struct tdr = CMOS_11
strip      Photoresist
diffuse temperature= 1050<C> time= 15<min>  

struct tdr = CMOS_12

#--- p-well ---#
photo mask = PMOS thickness = 1
implant  Boron  dose= 7.0e13<cm-2>  energy= 50<keV> tilt= 0 rotation= 0  
struct tdr = CMOS_13
strip      Photoresist

#--- n-well ---#
photo mask = NMOS thickness = 1
implant  phosphorus  dose= 5.0e13<cm-2>  energy= 130<keV> tilt= 0 rotation= 0  
struct tdr = CMOS_14
strip      Photoresist

# remove trench oxide #

etch cmp coord= 0.01
struct tdr = CMOS_15 
# gate oxide formation #
gas_flow clear
gas_flow name = O2 pressure = 1.0<atm>  flowO2= 1.0<l/min>
temp_ramp name = gate_Oxide clear
temp_ramp name = gate_Oxide time = 7.5<min> temperature= 800.0<C> gas.flow= O2 
diffuse temp.ramp = gate_Oxide
struct tdr = CMOS_16 

# --------------------
# Poly gate deposition
# --------------------
deposit material= {PolySilicon} type= anisotropic time= 1 rate= {0.05}
struct tdr = CMOS_17

## Poly gate pattern/etch
# ----------------------

etch material = {PolySilicon} type = anisotropic time = 1 rate= {0.05} \
mask = gate_mask

struct tdr= CMOS_18 ; # PolyGate

#--- N- doping ---#
photo mask = n-well thickness = 1
implant  Phosphorus  dose = 5.0e13<cm-2>  energy = 20<keV> tilt = 0 rotation = 0  
struct tdr= CMOS_19
strip Photoresist
struct tdr = CMOS_20

#--- P- doping ---#
photo mask = p-well thickness = 1
struct tdr = CMOS_21

implant  BF2  dose = 5.0e13<cm-2>  energy = 20<keV> tilt = 0 rotation = 0  

strip Photoresist
struct tdr = CMOS_22

#--- oxide spacer --#
deposit material= {Oxide} type = isotropic thickness = 10<nm>
struct tdr = CMOS_23

etch material = {Oxide} type = anisotropic thickness = 10<nm>

struct tdr = CMOS_24
#----- N+ Doping ----#
photo mask = PMOS thickness = 1
struct tdr = CMOS_25

implant  Phosphorus  dose = 10.0e15<cm-2>  energy = 10<keV> tilt = 0 rotation = 0  
struct tdr = CMOS_26
strip Photoresist
struct tdr = CMOS_27

#----- P+ Doping ----#
photo mask = NMOS thickness = 1
struct tdr = CMOS_28

implant  BF2  dose = 10.0e15<cm-2>  energy = 5<keV> tilt = 0 rotation = 0  
struct tdr = CMOS_29

strip Photoresist
struct tdr = CMOS_30

#----- remove remaning oxide ------#
etch material = {Oxide} type = anisotropic thickness = 2<nm>
struct tdr = CMOS_31

#------ deposit Titanium ------#
deposit material = {Titanium} thickness = 30<nm>
struct tdr = CMOS_32

#----- rapid thermal annealing -----#
diffuse temperature= 650<C> time= 10<s>  
struct tdr = CMOS_33

#----- remove excess Titanium ------#
etch material = {Titanium} type = isotropic thickness = 36<nm>
struct tdr = CMOS_34

exit
