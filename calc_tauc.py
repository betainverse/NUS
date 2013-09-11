#!/usr/bin/python
"""
calc_tauc.py uses the method outlined in section 1.4 of Cavanaugh to 
estimate tauc for given molecular weight and temperature
"""
import math


#viscosity of water values taken from:
#http://www.engineeringtoolbox.com/water-dynamic-kinematic-viscosity-d_596.html
#note that D2O is significantly more viscous, typically resulting in
#25% longer rotational correlation times
visc={} # N s m-2
visc[0  ]=1.787*10**-3 
visc[5  ]=1.519*10**-3 
visc[10 ]=1.307*10**-3 
visc[20 ]=1.002*10**-3
visc[25 ]=0.890*10**-3 
visc[30 ]=0.798*10**-3
visc[35 ]=0.719*10**-3 
visc[40 ]=0.653*10**-3 
visc[50 ]=0.547*10**-3 
visc[60 ]=0.467*10**-3 
visc[70 ]=0.404*10**-3 
visc[80 ]=0.355*10**-3 
visc[90 ]=0.315*10**-3 
visc[100]=0.282*10**-3  

#For other values:
#http://www.wolframalpha.com/input/?i=viscosity+of+water+at+35C


T=298 #K
Mr=24000 #g/mol

def calcRadius(molwt):
    pi=math.pi
    V=0.73 #cm3/g -> divide by 100 to convert to m
    Na=6.02*10**23 #mol-1
    rw= 3.2*10**-10 # m (1.6-3.2Angstroms)    
    nowater=(((3*V*molwt)/(4*pi*Na))**(1.0/3.0))/100
    return nowater+rw

def getvisc(T):
    To=273.16
    muo=0.001792
    a = -1.94
    b = -4.8
    c = 6.74
    rhs = a+b*(To/T)+c*(To/T)**2
    rhs2= rhs+math.log(muo)
    return math.e**rhs2
#    return visc[10*int(round((T-273)/10))]


def calcTauC(molwt,T):
    pi=math.pi
    kB=1.38*10**-23 #m2 kg s-2 K-1
    front = 4*pi/(3*T)
    middle = getvisc(T)
    back = (calcRadius(molwt)**3)/kB
    return front*middle*back*10**9 # convert to ns from s


#print calcTauC(24000,293)
#print getvisc(273+30)
#print getvisc(313.15)

for mw in range(10000,62000,2000):
    for T in range(10,40,5):
        TK = T+273.15
        print mw,T,calcTauC(mw,TK)







































