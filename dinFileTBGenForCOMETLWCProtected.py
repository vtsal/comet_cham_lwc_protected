# dinFileGen.py
# Version 3
# William Diehl
# 6 Aug 2017
# creates FOBOS-ready dinFile.txt of input width NUMCHAR
# Expects pdi.txt, sdi.txt, and do.txt are 1) generated from aeadtvgen v2.0.0, and 2) are in same directory
# Creates one (1) dinFile.txt, containing NUMTRACES number of test vectors, in a "fixed versus random" format
# Creates the fvrchoice.txt file, which has a 0 for fixed vectors and one for random vectors

import os
import sys
import random



bus_width = 0
share = 0
rand_bytes = 0
num_traces = 0
randomness = 0
pdi_file_path = ""
sdi_file_path = ""
do_file_path = ""
preDinFile_data = ""
if(len(sys.argv) > 1):
    for element in range(1, len(sys.argv)):
        if(sys.argv[element].lower() == "-bus_width"):
            bus_width = sys.argv[element + 1]
            
        if(sys.argv[element].lower() == "-share"):
            share = sys.argv[element + 1]
            
        if(sys.argv[element].lower() == "-rand_num_bytes"):
            rand_bytes = sys.argv[element + 1]
        
        if(sys.argv[element].lower() == "-traces"):
            num_traces = sys.argv[element + 1]

        if(sys.argv[element].lower() == "-random"):
            randomness = 1

        if(sys.argv[element].lower() == "-pdi_file"):
            pdi_file_path = sys.argv[element + 1]

        if(sys.argv[element].lower() == "-sdi_file"):
            sdi_file_path = sys.argv[element + 1]
            
        if(sys.argv[element].lower() == "-do_file"):
            do_file_path = sys.argv[element + 1]
            
        if(sys.argv[element].lower() == "-h" or sys.argv[element].lower() == "-help"):
            print """
Usuage: dinFileTBGen_modified.py -bus_width <bus width in bits> -share <no of shares> -rand_num_bytes <size of random number in bytes> -traces <number of traces> -random -pdi_file <file name with path> -sdi_file <file name with path> -do_file <file name with path> 

Parameters explained:
1. -bus_width: Mandatory param, can have values 8, 16, 32. If not provided, script will thow an error and exit.

2. -share: Mandatory param, can have value 1 only for COMET LWC Protected implementation. If not provided, script will thow an error and exit.
                
3. -rand_num_bytes: Mandatory param. If not provided, script will thow an error and exit.

4. -traces: Mandatory param. If not provided, script will thow an error and exit.

5. -random: Optional param. This param tells the script to generate combination of random and fixed test vectors. If not provided, script will only generate fixed test vectors.

6. -pdi_file: Optional param. If not provided, script will assume that pdi.txt is present in execution directory and pick that file..

7. -sdi_file: Optional param. If not provided, script will assume that sdi.txt is present in execution directory and pick that file.

8. -do_file: Optional param. If not provided, script will assume that do.txt is present in execution directory and pick that file.

            """
            exit()

if(share == 0):
    print("Input value for Share is not correct. Exiting!!")
    exit()

if(bus_width == 0):
    print("Input value for Bus Width is not correct. Exiting!!")
    exit()
    
if(rand_bytes == 0):
    print("Input value for Random Number Bytes is not correct. Exiting!!")
    exit()

if(num_traces == 0):
    print("Input value for number of traces is not correct. Exiting!!")
    exit()
    
if(randomness == 0):
    print("Randomness is not selected. Generating fixed test vectors.")
else:
    print("Randomness is selected. Generating combination of fixed and random test vectors.")
            
NUMPDIBYTES = 0
NUMSDIBYTES = 0
NUMRNDBYTES = int(rand_bytes)
BUSWIDTH = int(bus_width)  # bits of PW
MAKESHARE = int(share)
hexlist = ['A','B','C','D','E','F']
numlist = ['0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F']


#NUMCHAR = 2
NUMCHAR = BUSWIDTH/4
#NUMRNDLINES = 300
#NUMTRACES = 2000
NUMTRACES = int(num_traces)

if(pdi_file_path == ""):
    print "pdi file name not enetred. Selecting pdi.txt in the excution directory."
    pdifilename = "pdi.txt"
else:
    pdifilename = pdi_file_path
    
if(sdi_file_path == ""):
    print "sdi file name not enetred. Selecting sdi.txt in the excution directory."
    sdifilename = "sdi.txt"
else:
    sdifilename = sdi_file_path

if(do_file_path == ""):
    print "do file name not enetred. Selecting do.txt in the excution directory."
    dofilename = "do.txt"
else:
    dofilename = do_file_path
#rdifilename = "rdi.txt"
dinFileName = "dinFile.txt"
fvrchoicefilename = "fvrchoicefile.txt"


def hex2num(s):
        result = 16 * numlist.index(s[0]) + numlist.index(s[1])
        return result

def returnHex(x):
    
        if (x < 10):
            s = str(x)
        else:
            s = hexlist[x - 10]
        return s

# return a 2-digit hex string
def returnHex2(x):
	if (x < 16):
		s = '0' + returnHex(x)
	else:
		s = returnHex(x/16) + returnHex(x%16) 		
	return s
    
# return a 4-digit hex string
def returnHex4(x):
        if (x < 16):
                s = '000' + returnHex(x)
        else:
            if (x < 256):
                    s = '00' + returnHex(x/16) + returnHex(x%16)
            else:
                if (x < 4096):
                    y1 = x/256
                    y2 = x - 256*y1
                    s = '0' + returnHex(y1) + returnHex(y2/16) + returnHex(y2%16)
                else:
                    y1 = x/4096
                    y2 = x - 4096*y1
                    y3 = y2/256
                    y4 = y2 - y3*256
                    
                    s = returnHex(y1) + returnHex(y3) + returnHex(y4/16) + returnHex(y4%16)
                    
        return s

# input is BUSWIDTH/4-digit hex string
# output is BUSWIDTH/2 digit hex string 
def makeShare(instrng, share):
    xastrng = ""
    xbstrng = ""
    xcstrng = ""
    xdstrng = ""
    #for i in range (0,BUSWIDTH/(8*share)):

    if(share == 1):
        return instrng

    if(share == 2):
        x = int(instrng.upper(), 16)
        xa = int(random.random()*(2**(BUSWIDTH)))
        xb = x ^ xa
        xastrng = xastrng + hex(xa)[2:].zfill(BUSWIDTH/4)
        xbstrng = xbstrng + hex(xb)[2:].zfill(BUSWIDTH/4)
        
        return (xastrng + xbstrng)
    
    if(share == 3):
        x = int(instrng.upper(), 16)
        xa = int(random.random()*(2**(BUSWIDTH)))
        xb = int(random.random()*(2**(BUSWIDTH)))
        xc = xa ^ xb
        xd = x ^ xc
        xastrng = xastrng + hex(xa)[2:].zfill(BUSWIDTH/4)
        xbstrng = xbstrng + hex(xb)[2:].zfill(BUSWIDTH/4)
        xcstrng = xcstrng + hex(xd)[2:].zfill(BUSWIDTH/4)
        
        return (xastrng.upper() + xbstrng.upper() + xcstrng.upper())
    
    
    if(share == 4):
        x = int(instrng.upper(), 16)
        xa = int(random.random()*(2**(BUSWIDTH)))
        xb = int(random.random()*(2**(BUSWIDTH)))
        xc = int(random.random()*(2**(BUSWIDTH)))
        xd = xa ^ xb
        xe = xd ^ xc
        xf = x ^ xe
        xastrng = xastrng + hex(xa)[2:].zfill(BUSWIDTH/4)
        xbstrng = xbstrng + hex(xb)[2:].zfill(BUSWIDTH/4)
        xcstrng = xcstrng + hex(xc)[2:].zfill(BUSWIDTH/4)
        xdstrng = xdstrng + hex(xf)[2:].zfill(BUSWIDTH/4)
        
        return (xastrng.upper() + xbstrng.upper() + xcstrng.upper() + xdstrng.upper())
    
    
    

# makes string of NUMRNDBYTES in hex digits    
def makeRndSeed():
    result = ""
    for i in range (0, NUMRNDBYTES):
        result = result + returnHex2(int(random.random()*256))
    return result


def dinFileGen(tracenum):
    global NUMPDIBYTES
    global NUMSDIBYTES
    global preDinFile_data

    NUMBYTES = 0
       

# parse pdi.txt
# first pass
    
    pdiFileData = ""
    pdifile = open(pdifilename,'r')
    t = pdifile.readlines()
    pdifile.close()
        
    writefile.write('00C0')
    
    if (random.random()<0.5 or randomness == 0):
        # fixed pdi
        fvrchoicefile.write('0')
                
        for line in t:
            if("NUM" in line):
                continue
            
            if("INS" in line) or ("HDR" in line) or ("DAT" in line):
                pdiFileData = pdiFileData + line.split("=")[-1].strip(" \n")

        writefile.write(hex(len(pdiFileData)/2)[2:].zfill(4))        
        writefile.write(pdiFileData)
    else:   
         # random pdi
        fvrchoicefile.write('1')
        
        for line in t:
            if("NUM" in line):
                continue
            
            if("INS" in line):
                pdiFileData = pdiFileData + line.split("=")[-1].strip(" \n")
                
            if("HDR" in line):
                pdiFileData = pdiFileData + line.split("=")[-1].strip(" \n")
                
            if("DAT" in line):
                lengthData = len(line.split("=")[-1].strip(" \n"))/2
                
                randomData = ""
                for length in range(0, lengthData/4):
                    randomData = randomData + hex(int(random.random()*(2**32)))[2:].zfill(8)
                    
                    #if("L" in randomData):
                    #    randomData = randomData[:-1]
                
                #randomData = randomData.zfill(2)
                
                pdiFileData = pdiFileData + randomData
                
        writefile.write(hex(len(pdiFileData)/2)[2:].zfill(4))        
        writefile.write(pdiFileData)
        
    print ("NUMBYTES of pdi.txt = " + str(len(pdiFileData)/2))
    #exit()

# parse sdi.txt
# first pass

    NUMBYTES = 0

    sdifile = open(sdifilename,'r')
    t = sdifile.readlines()
    sdifile.close()

# write sdi.txt header and number of bytes
    sdiFileData = ""
    writefile.write('00C1')
    
    for line in t:
            if("NUM" in line):
                continue
            
            if("INS" in line) or ("HDR" in line) or ("DAT" in line):
                sdiFileData = sdiFileData + line.split("=")[-1].strip(" \n")
                
    writefile.write(hex(len(sdiFileData)/2)[2:].zfill(4))        
    writefile.write(sdiFileData)
     
    print ("NUMBYTES of sdi.txt = " + str(len(sdiFileData)/2))
    
    rndseed = makeRndSeed()
    
    
    writefile.write("00C2" + returnHex4(NUMRNDBYTES)+rndseed)
    #writefile.write(rndseed)
    
    
    
    NUMBYTES = 0

    dofile = open(dofilename,'r')
    t = dofile.readline()
    while (t != ""):
        if ((t.find('#')==0) or (t.lstrip()=="")):
            t = dofile.readline()
        else:
            delim = t.find(' = ')
            t = t[delim+3:len(t)-1]
            NUMBYTES = NUMBYTES + len(t)/2
            t = dofile.readline()

    dofile.close()

# write do.txt header and number of bytes

    print ("NUMBYTES of do.txt = " + str(NUMBYTES*3))

    writefile.write('0081')
    writefile.write(returnHex4(NUMBYTES*3))
    #preDinFile_data = preDinFile_data + '0081' + returnHex4(NUMBYTES)

# write start command

    writefile.write('0080')
    writefile.write('0001\n')
    #preDinFile_data = preDinFile_data + '0080' + '0001\n'
    print ("Test Vector # " + str(tracenum) + " created.")

# main

writefile = open(dinFileName,'w') 
fvrchoicefile = open(fvrchoicefilename,'w')
#rdifile = open(rdifilename,'r')

TRACENUM = 0

for i in range (0, NUMTRACES):
    dinFileGen(TRACENUM)
    TRACENUM = TRACENUM + 1
#rdifile.close()
fvrchoicefile.close()
writefile.close()

"""

# default input - output files
predinfilename = "preDinFile.txt"
dinfilename = "dinFile.txt"

readfile = open(predinfilename,'r')
writefile = open(dinfilename,'w') 

TRACENUM = 0

t = readfile.readline()

while (t != ""):
    pdiseg = t[8:8+NUMPDIBYTES*2]
    
    pdisegmasked = ""
    
    for i in range (0,NUMPDIBYTES/(BUSWIDTH/8)):
        pdisegmasked = pdisegmasked + makeShare(pdiseg[i*(BUSWIDTH/4):i*(BUSWIDTH/4)+(BUSWIDTH/4)], MAKESHARE)
    
    sdiseg = t[16+NUMPDIBYTES*2:16+NUMPDIBYTES*2+NUMSDIBYTES*2]

    sdisegmasked = ""
    for i in range (0,NUMSDIBYTES/(BUSWIDTH/8)):
        sdisegmasked = sdisegmasked + makeShare(sdiseg[i*(BUSWIDTH/4):i*(BUSWIDTH/4)+(BUSWIDTH/4)], MAKESHARE)

    
    rndseed = makeRndSeed()
    
    if(rndseed != ""):
        writestr = "00C0" + returnHex4(NUMPDIBYTES*MAKESHARE) + pdisegmasked + "00C1" + returnHex4(NUMSDIBYTES*MAKESHARE) + \
               sdisegmasked + "00C2" + returnHex4(NUMRNDBYTES) + rndseed + \
               t[16+NUMPDIBYTES*2+NUMSDIBYTES*2:32+NUMPDIBYTES*2+NUMSDIBYTES*2] + '\n'
    else:
        writestr = "00C0" + returnHex4(NUMPDIBYTES*MAKESHARE) + pdisegmasked + "00C1" + returnHex4(NUMSDIBYTES*MAKESHARE) + \
               sdisegmasked + t[16+NUMPDIBYTES*2+NUMSDIBYTES*2:32+NUMPDIBYTES*2+NUMSDIBYTES*2] + '\n'
 
    writefile.write(writestr)    
    #print ("Trace number: " + str(TRACENUM))
    TRACENUM = TRACENUM + 1
    t = readfile.readline()

readfile.close()
writefile.close()

#os.system("rm -rf preDinFile.txt")
"""
