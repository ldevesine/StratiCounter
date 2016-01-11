from pymatbridge import Matlab
import time

msession = Matlab(executable='/Applications/MATLAB_R2014b.app/bin/matlab')
msession.start()
results = msession.run_code("straticounter('sett_example.m')")
print results
time.sleep(60)
msession.stop()

