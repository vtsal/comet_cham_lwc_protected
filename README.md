# comet_cham_lwc_protected
3-share TI protected Comet Cham using 32-bit external interface and LWC protected development package
Interim solution for testing protected LWC AEAD architectures:

1. Develop an n-share protected LWC implementation, as shown in the protected CryptoCore (Note: Currently n=3 until these additions are generified to n = 1, 2, 3, or 4).

2. Insert the protected CryptoCore into the LWC HW development package, which is modified for protected implementations.  This consists of (modified) PreProcessor, (modified) PostProcessor, (addition) pdi_sipo, (addition) sdi_sipo, (addition) do_piso, (modified) LWC, and (modified) LWC_TB.

3. The LWC external interface and protocol are that which is defined in HW API for Lightweight Cryptography https://cryptography.gmu.edu/athena/LWC/LWC_HW_API.pdf.

4. To test an implementation using LWC_TB

a. Generate test vectors using cryptotvgen as before, namely pdi.txt, sdi.txt, and do.txt

b. Run genShared.py to generate pdiShared.txt and sdiShared.txt. These files will contain the contents of test vectors preseparated by software into n-shares.  The source of randomness for initial sharing can be random for each test vector, or fixed for all test vectors, to facilitate troubleshooting.  These will be used by LWC_TB as the input files.

c. Run LWC_TB as normal using pdiShared.txt, sdiShared.txt, and the normal do.txt.  The test bench functions as previously.

d. The LWC_TB currently uses fixed data to supply rdi_data for any randomness consumed in the application.

5. To test an implementation using FOBOS:

a. Use pdiShared.txt, sdiShared.txt, and do.txt to generate a FOBOS test vector using dinFileTBGenForCOMETLWCProtected.py.

b. Insert the resulting dinFile.txt into fobos_dut_tb, and simulate the file.

c. Capture the result as doutFile.txt.  The doutFile.txt will contain output shares that remain separated into n-shares.  Either examine them manually for correctness, or run doutFileWithoutShares.py to produce a recombined output, which can be manually compared with do.txt.
