import sys

if(len(sys.argv) > 1):
    for element in range(1, len(sys.argv)):
        if(sys.argv[element].lower() == "-h" or sys.argv[element].lower() == "-help"):
            print """
Usuage: outputConvertWithoutShares.py

When you run this script, it assumes that the input file has name dinFile.txt and will generate output file named doutFileWithoutShares.txt.
Input file must be in the same directory from which the script is executed.
"""
            exit()

outFileHandle = open("doutFile.txt", 'r')
outFileContents = outFileHandle.readlines()

outFileWrite = open("doutFileWithoutShares.txt", "w")

for line in outFileContents:
    content = line.strip("\n").replace(" ", "")
    for i in range(0, len(content),24):
        x1 = int(content[i:i+8], 16)
        x2 = int(content[i+8:i+16], 16)
        x3 = int(content[i+16:i+24], 16)
        
        outFileWrite.write(hex(x1^x2^x3)[2:].zfill(8).upper())
        
    outFileWrite.write("\n")
    
outFileWrite.close()

        
        
    
