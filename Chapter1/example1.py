from itoolkit import *
from itoolkit.transport import DirectTransport
itransport = DirectTransport()

itool = iToolKit()

# itool.add(iCmd('addlible', 'addlible rthompson1'))

itool.add( 
          iPgm('rpgle_results', 'EXAMPLE1', {'lib': 'RTHOMPSON1'})
          .addParm(iData('InParm','20a','IBMi'))
          .addParm(iData('OutParm','200a',' ')) 
         )
         
itool.call(itransport)

# results are returned as a dictionary formatted as Json

rpgle_results = itool.dict_out('rpgle_results')

if 'success' in rpgle_results:
    print(rpgle_results)
else:
    print('Errors occurred.')
    
# parse the Json response from the dictionary

print('\n')
print("OutParm: ", rpgle_results['OutParm'])
print("Status: ", rpgle_results['success'])
