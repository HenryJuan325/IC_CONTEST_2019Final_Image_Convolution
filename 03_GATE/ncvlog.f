#-sv tb_term.sv 
#SME.v 
#+access+r 
#+define+RTL
#+debug
#+notimingchecks

CONV_syn.v
-timescale 1ns/10ps
testfixture.v
#-v ~/IC_CONTEST/CBDK_IC_Contest_v2.5/Verilog/tsmc13_neg.v 
-v ./tsmc13_neg.v
+define+SDF 
+ncmaxdelays
+debug
