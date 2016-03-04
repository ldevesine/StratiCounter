from pymatbridge import Matlab
import time

def main():
	mlab = Matlab(executable='/Applications/MATLAB_R2014b.app/bin/matlab')
	mlab.start()
	model = mlab.run_func("straticounter_variableinput",'name',['Cl','nssS'],'./Data/data_example.mat',202,210,[],0.01,0)
	time.sleep(1)
	print model
	mlab.run_func("straticounter_analysis",model['result'])
	time.sleep(1)
	print info
	mlab.stop()
main()

