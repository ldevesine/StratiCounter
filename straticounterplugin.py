from pymatbridge import Matlab
import time

base_file = open('Settings/sett_pytemplate.m', 'r')
generated_file = open('Settings/sett_generated.m', 'w')

for line in base_file:
	new_line = line.replace('_NAME_', 'NEEM-2011-S1_example')
	new_line = new_line.replace('_SPECIES_', "'Cl','nssS'")
	new_line = new_line.replace('_DATAPATH_', './Data/data_example.mat')
	new_line = new_line.replace('_DSTART_', '202')
	new_line = new_line.replace('_DEND_', '210')
	new_line = new_line.replace('_TIEPTS_', '')
	new_line = new_line.replace('_RESOLUTION_', '10^-2')
	new_line = new_line.replace('_MANCOUNTS_', 'counts_example.txt')
	new_line = new_line.replace('_MANUNITS_', 'AD')
	new_line = new_line.replace('_TIEPTS_', 'AD')
	generated_file.write(new_line)

msession = Matlab(executable='/Applications/MATLAB_R2014b.app/bin/matlab')
msession.start()
results = msession.run_code("straticounter('sett_generated.m')")
print results
time.sleep(60)
msession.stop()

